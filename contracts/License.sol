// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MarketContract.sol";
import "./CommonUtils.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract License is
  Context,
  AccessControlEnumerable,
  ERC1155Burnable,
  ERC1155Pausable,
  Ownable
{
  using Counters for Counters.Counter;

  //Constants and variables
  Counters.Counter internal _licenseBundleId;
  bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  ICommonUtils internal commonUtils;

  mapping(uint256 => string) public _uris;

  // Events
  event LicenseMintEvent(uint256 indexed id, string uri);

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the account that
   * deploys the contract.
   */
  constructor(address _commonUtilsAddress) ERC1155("") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    commonUtils = ICommonUtils(_commonUtilsAddress);
  }

  /**
   * @dev Returns the actual `baseURI` for token type `id`.
   * @param tokenId token ID to retrieve the uri from
   * @return URI from token ID
   */
  function uri(uint256 tokenId) public view override returns (string memory) {
    return (_uris[tokenId]);
  }

  /**
   * @dev Sets token URI for token type `id`.
   * @param tokenId token ID receiving the uri
   * @param _uri URI to set to token ID
   */
  function setTokenUri(uint256 tokenId, string memory _uri) public {
    require(bytes(_uris[tokenId]).length == 0, "Cannot set uri twice");
    _uris[tokenId] = _uri;
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   * See {ERC1155-_mint}.
   * @param _signer address of the creator
   * @param _mintURI URI of the song
   * @param _amount amount of licenses to be created
   * @param _erc721Reference reference of the Master NFT
   */
  function mintLicenses(
    address _signer,
    string memory _mintURI,
    uint256 _amount,
    bytes memory _erc721Reference
  ) public onlyMaster {
    _licenseBundleId.increment();
    uint256 currentLicenseBundleId = _licenseBundleId.current();

    mint(_signer, currentLicenseBundleId, _mintURI, _amount, _erc721Reference);
  }

  /**
   * @dev Mint Master
   * @param _signer address of the creator
   * @param _currentLicenseBundleId ID of the Master NFT
   * @param _mintURI URI of the song
   * @param _amount amount of licenses to be created
   * @param _erc721Reference reference of the Master NFT
   */
  function mint(
    address _signer,
    uint256 _currentLicenseBundleId,
    string memory _mintURI,
    uint256 _amount,
    bytes memory _erc721Reference
  ) private {
    setTokenUri(_currentLicenseBundleId, _mintURI);
    _mint(_signer, _currentLicenseBundleId, _amount, _erc721Reference);

    emit LicenseMintEvent(_currentLicenseBundleId, _mintURI);
  }

  /**
   * @dev Keeps track of total minted nfts
   * @return total of minted license bundles
   */
  function totalTokens() public view returns (uint256) {
    return _licenseBundleId.current();
  }

  /**
   * @dev Pause
   *
   * See {ERC1155Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
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
   *
   * See {ERC1155Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
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
    override(AccessControlEnumerable, ERC1155)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  modifier onlyMaster() {
    require(msg.sender == commonUtils.getContractAddressFrom("Master"));
    _;
  }

  /**
   * @dev Transfer license
   * @param _signer From address
   * @param _buyer To address
   * @param _currentLicenseBundleId ID of the token bundle to be transferred
   * @param _amountToPurchase Amount to be transferred
   */
  function transferLicenses(
    address _signer,
    address _buyer,
    uint256 _currentLicenseBundleId,
    uint256 _amountToPurchase
  ) public {
    _safeTransferFrom(
      _signer,
      _buyer,
      _currentLicenseBundleId,
      _amountToPurchase,
      "0x"
    );
  }

  /**
   * @dev License balance of
   * @param _account From address
   * @param _tokenId Token ID to search for
   */
  function licensesBalanceOf(address _account, uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    return balanceOf(_account, _tokenId);
  }
}
