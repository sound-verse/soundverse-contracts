// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILicense.sol";
import "./CommonUtils.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "hardhat/console.sol";

contract Master is
  AccessControlEnumerable,
  ERC721URIStorage,
  Pausable,
  Ownable,
  ERC2981
{
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  // Contracts and libraries
  ICommonUtils internal commonUtils;
  ILicense internal licensesContract;

  // Constants and variables
  bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  string internal constant LICENSE = "License";
  uint256 internal constant MIN_SUPPLY = 2;
  Counters.Counter private _tokenIdTracker;

  // Events
  event MasterMintEvent(uint256 indexed id, string uri);

  /**
   * @dev Constructor of Master NFT
   * @param _commonUtilsAddress CommonUtils contract address
   */
  constructor(address _commonUtilsAddress) ERC721("SoundVerseMaster", "SVM") {
    _setupRole(PAUSER_ROLE, _msgSender());
    commonUtils = ICommonUtils(_commonUtilsAddress);
  }

  /**
   * @dev Initializes the contracts with respective interfaces
   */
  function initializeContracts() internal {
    address licenseAddress = commonUtils.getContractAddressFrom(LICENSE);
    licensesContract = ILicense(licenseAddress);
  }

  // Creators and contributors *Master Royalties*
  struct Contributor {
    address contributorAddress;
    uint96 royaltyFeeInBips;
  }

  Contributor[] public contributors;

  /**
   * @dev Project creator mapping
   */
  mapping(uint256 => Contributor[]) public _creatorsAndContributorsTemp;
  mapping(uint256 => Contributor[]) public _creatorsAndContributors;

  /**
   * @dev Sets token contributors for token type `id`.
   * @param _tokenId token ID receiving the creator
   * @param _contributorAddresses Address of contributor of the project
   * @param _royaltyFeeInBips percentage of royalty for contributor of the project
   */
  function addContributorsToMaster(
    uint256 _tokenId,
    address[] memory _contributorAddresses,
    uint96[] memory _royaltyFeeInBips
  ) public {
    uint96 totalPercentage = 0;
    for (uint256 i = 0; i < _contributorAddresses.length; i++) {
      Contributor memory newContributor = Contributor(
        _contributorAddresses[i],
        _royaltyFeeInBips[i]
      );

      totalPercentage += _royaltyFeeInBips[i];
      if (totalPercentage >= 100) {
        require(
          totalPercentage <= 100,
          "Maximum percentage exceeded for royalties"
        );
      } else {
        contributors.push(newContributor);
      }
    }
    _creatorsAndContributors[_tokenId] = contributors;
  }

  /**
   * @dev Sets token contributors from temp to original for token type `id`.
   * @param _tokenId token ID receiving the creator
   */
  function setTokenContributors(uint256 _tokenId) internal {
    Contributor[] storage contributorsToSet = _creatorsAndContributorsTemp[
      _tokenId
    ];
    _creatorsAndContributors[_tokenId] = contributorsToSet;
  }

  /**
   * @param _tokenId token ID receiving the creator
   * @return address from creator of the project
   */
  function creators(uint256 _tokenId)
    internal
    view
    returns (Contributor[] storage)
  {
    return _creatorsAndContributors[_tokenId];
  }

  function cleanUpContributorsTemp(uint256 _tokenId) public {
    //clean up array after assigning creators
    console.log("Cleanup Creators called....");
    for (
      uint256 i = 0;
      i < _creatorsAndContributorsTemp[_tokenId].length;
      i++
    ) {
      delete _creatorsAndContributorsTemp[i];
      i++;
    }
  }

  /**
   * @dev tokenURIs
   */
  mapping(uint256 => string) public _uris;

  /**
   * @dev TokenIDs from URIs
   */
  mapping(string => uint256) public _urisToIds;

  /**
   * @dev Returns the actual URI for TokenID.
   * @param _tokenId token ID to retrieve the uri from
   * @return URI from token ID
   */
  function uri(uint256 _tokenId) public view returns (string memory) {
    return (_uris[_tokenId]);
  }

  /**
   * @dev Returns the actual TokenID for a given URI
   * @param _uri URI to retrieve the TokenID from
   * @return URI from token ID
   */
  function tokenIdForURI(string memory _uri) public view returns (uint256) {
    return (_urisToIds[_uri]);
  }

  /**
   * @dev Sets tokenID for token URI.
   * @param _tokenId token ID for a given URI
   * @param _uri URI of NFT
   */
  function setTokenIDForURI(uint256 _tokenId, string memory _uri) internal {
    _urisToIds[_uri] = _tokenId;
  }

  /**
   * @dev Main minting function
   * Function to called by the BE to trigger Master and License minting
   * @param _signer address of creator
   * @param tokenURI URI of the song to be minted
   * @param _licensesAmount amount of licenses to mint linked to the Master NFT
   * @param _royaltyFeeInBips Percentage of royalty fees for creator
   * Finally approves the Marketplace to handle the Master
   */
  function createMasterItem(
    address _signer,
    string memory tokenURI,
    uint256 _licensesAmount,
    uint96 _royaltyFeeInBips
  ) public onlyMarketplace returns (uint256) {
    console.log("CREATE MASTER ITEM starting....");
    require(bytes(tokenURI).length > 0, "TokenUri can not be null");
    require(_licensesAmount >= MIN_SUPPLY, "Supply must be greater than 2");
    console.log("MINTITEM about to be called....");
    uint256 tokenId = mintItem(
      _signer,
      tokenURI,
      _licensesAmount,
      _royaltyFeeInBips
    );

    return tokenId;
  }

  /**
   * @dev Mint function that mints Master NFT and linked licenses
   * @param _signer address of creator
   * @param _mintURI URI of the song to be minted
   * @param _amountToMint amount of licenses to mint linked to the Master NFT
   * @param _royaltyFeeInBips Percentage of royalty fees for creator
   */
  function mintItem(
    address _signer,
    string memory _mintURI,
    uint256 _amountToMint,
    uint96 _royaltyFeeInBips
  ) private returns (uint256) {
    console.log("MINTITEM STARTING....");
    _tokenIdTracker.increment();
    uint256 currentTokenId = _tokenIdTracker.current();

    require(bytes(_uris[currentTokenId]).length == 0, "Cannot set URI twice");

    // Saves creator in mapping with tokenId
    setTokenContributors(currentTokenId);
    console.log("CleanupCreators about to be called....");
    cleanUpContributorsTemp(currentTokenId);

    _safeMint(_signer, currentTokenId);
    _setTokenURI(currentTokenId, _mintURI);
    setTokenIDForURI(currentTokenId, _mintURI);
    console.log("setRoyaltyFees about to be called....");
    setRoyaltyFeesForContributors(currentTokenId);
    emit MasterMintEvent(currentTokenId, _mintURI);

    initializeContracts();

    console.log("MINTLICENSES about to be called....");
    licensesContract.mintLicenses(
      _signer,
      _mintURI,
      _amountToMint,
      commonUtils.toBytes(currentTokenId),
      _royaltyFeeInBips
    );
    return currentTokenId;
  }

  /**
   * @dev Transfer Master
   * @param _signer From address
   * @param _buyer To address
   * @param _tokenId ID of the token to be transferred
   */
  function transferMaster(
    address _signer,
    address _buyer,
    uint256 _tokenId
  ) public {
    _safeTransfer(_signer, _buyer, _tokenId, "");
  }

  /**
   * @dev Burn tokens
   * @param tokenId ID of the token to be burned
   */
  function burnUnpublishedItem(uint256 tokenId) public onlyOwner {
    _burn(tokenId);
  }

  /**
   * @dev Keeps track of total minted nfts
   * @return current number of minted tokens
   */
  function totalTokens() public view returns (uint256) {
    return _tokenIdTracker.current();
  }

  /**
   * @dev Pause
   * See {ERC1155Pausable} and {Pausable-_pause}.
   * Requirements:
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "Must have pauser role to pause"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   * See {ERC1155Pausable} and {Pausable-_unpause}.
   * Requirements:
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "Must have pauser role to unpause"
    );
    _unpause();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  modifier onlyMarketplace() {
    require(msg.sender == commonUtils.getContractAddressFrom("MarketContract"));
    _;
  }

  function setRoyaltyFees(
    uint256 _tokenId,
    address _receiver,
    uint96 _royaltyFeeInBips
  ) internal {
    _setTokenRoyalty(_tokenId, _receiver, _royaltyFeeInBips);
  }

  function setRoyaltyFeesForContributors(uint256 _tokenId) internal {
    Contributor[] storage contributorsForRoyalty = _creatorsAndContributorsTemp[_tokenId];
    for (uint256 i = 0; i < contributorsForRoyalty.length; i++) {
      _setTokenRoyalty(
        _tokenId,
        contributorsForRoyalty[i].contributorAddress,
        contributorsForRoyalty[i].royaltyFeeInBips
      );
    }
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    public
    view
    override
    returns (address, uint256)
  {
    return royaltyInfo(_tokenId, _salePrice);
  }
}
