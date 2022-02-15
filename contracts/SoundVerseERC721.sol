// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC1155.sol";
import "./CommonUtils.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ISoundVerseERC721 {
    function createMasterItem(
        address buyer,
        address signer,
        string memory tokenURI,
        uint256 _licensesAmount
    ) external;
}

contract SoundVerseERC721 is
    AccessControlEnumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Contracts and libraries
    ICommonUtils public commonUtils;
    ISoundVerseERC1155 public licensesContract;

    // Constants and variables
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public constant SV1155 = "SoundVerseERC1155";
    uint256 public constant MIN_SUPPLY = 2;
    Counters.Counter private _tokenIdTracker;

    // Events
    event MasterMintEvent(uint256 indexed id);

    /**
     * @dev Constructor of Master NFT
     * @param _commonUtilsAddress CommonUtils contract address
     */
    constructor(address _commonUtilsAddress) ERC721("SoundVerseMaster", "SVM") {
        _setupRole(PAUSER_ROLE, _msgSender());

        commonUtils = ICommonUtils(_commonUtilsAddress);
        address sv1155 = commonUtils.getContractAddressFrom(SV1155);
        licensesContract = ISoundVerseERC1155(sv1155);
    }

    /**
     * @dev Project creator mapping
     */
    mapping(uint256 => address) private _creators;

    /**
     * @dev Sets token creator for token type `id`.
     * @param tokenId token ID receiving the creator
     * @param _creator Creator of the project
     */
    function setTokenCreator(uint256 tokenId, address _creator) internal {
         _setupRole(MINTER_ROLE, _creator);
        _creators[tokenId] = _creator;
    }

    /**
     * @param tokenId token ID receiving the creator
     * @return address from creator of the project
     */
    function creator(uint256 tokenId) internal view returns (address) {
        return _creators[tokenId];
    }

    /**
     * @dev tokenURIs
     */
    mapping(uint256 => string) private _uris;

    /**
     * @dev Returns the actual `baseURI` for token type `id`.
     * @param tokenId token ID to retrieve the uri from
     * @return URI from token ID
     */
    function uri(uint256 tokenId) public view returns (string memory) {
        return (_uris[tokenId]);
    }

    /**
     * @dev Main minting function
     * Function to called by the BE to trigger Master and License minting
     * @param _buyer address of the buyer
     * @param _signer address of creator
     * @param tokenURI URI of the song to be minted
     * @param _licensesAmount amount of licenses to mint linked to the Master NFT
     * Finally approves the Marketplace to handle the Master
     */
    function createMasterItem(
        address _buyer,
        address _signer,
        string memory tokenURI,
        uint256 _licensesAmount
    ) public {
        require(bytes(tokenURI).length > 0, "TokenUri can not be null");
        require(_licensesAmount >= MIN_SUPPLY, "Supply must be greater than 2");
        mintItem(_buyer, _signer, tokenURI, _licensesAmount);
    }

    /**
     * @dev Mint function that mints Master NFT and linked licenses
     * @param _buyer address of the buyer
     * @param _signer address of creator
     * @param _mintURI URI of the song to be minted
     * @param _amount amount of licenses to mint linked to the Master NFT
     */
    function mintItem(
        address _buyer,
        address _signer,
        string memory _mintURI,
        uint256 _amount
    ) private {
        uint256 currentTokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        require(
            bytes(_uris[currentTokenId]).length == 0,
            "Cannot set URI twice"
        );

        // Creator in mapping speichern anhand tokenId
        setTokenCreator(currentTokenId, _signer);

        _safeMint(_signer, currentTokenId);
        _setTokenURI(currentTokenId, _mintURI);
        emit MasterMintEvent(currentTokenId);

        _transfer(_signer, _buyer, currentTokenId);

        licensesContract.mintLicenses(
            _signer,
            _buyer,
            _mintURI,
            _amount,
            commonUtils.toBytes(currentTokenId)
        );
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
        override(AccessControlEnumerable, ERC721)
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
}
