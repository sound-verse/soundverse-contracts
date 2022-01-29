// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MarketContract.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoundVerseERC1155 is
    Context,
    AccessControlEnumerable,
    ERC1155Burnable,
    ERC1155Pausable,
    Ownable
{
    using Counters for Counters.Counter;

    //Constants and variables
    Counters.Counter private _licenseBundleId;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant MIN_SUPPLY = 2;
    address public marketplaceAddress;

    mapping(uint256 => string) private _uris;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the account that
     * deploys the contract.
     * @param _marketplaceAddress Address of the marketplace
     */
    constructor(address _marketplaceAddress) ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        marketplaceAddress = _marketplaceAddress;
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
    function setTokenUri(uint256 tokenId, string memory _uri) internal {
        require(bytes(_uris[tokenId]).length == 0, "Cannot set uri twice");
        _uris[tokenId] = _uri;
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     * @param _to address of the receiver
     * @param _mintURI URI of the song
     * @param _amount amount of licenses to be created
     * @param _erc721Reference reference of the Master NFT
     */
    function mintLicenses(
        address _to,
        string memory _mintURI,
        uint256 _amount,
        bytes memory _erc721Reference
    ) external {
        uint256 currentLicenseBundleId = _licenseBundleId.current();
        require(bytes(_mintURI).length != 0, "URI can not be empty");
        require(_amount >= MIN_SUPPLY, "Supply must be greater than 2");

        setApprovalForAll(marketplaceAddress, true);

        mint(_to, currentLicenseBundleId, _mintURI, _amount, _erc721Reference);
    }

    /**
     * @dev Mint Master
     *
     * @param _to address of the receiver
     * @param _currentLicenseBundleId ID of the Master NFT
     * @param _mintURI URI of the song
     * @param _amount amount of licenses to be created
     * @param _erc721Reference reference of the Master NFT
     *
     */
    function mint(
        address _to,
        uint256 _currentLicenseBundleId,
        string memory _mintURI,
        uint256 _amount,
        bytes memory _erc721Reference
    ) private {
        _licenseBundleId.increment();

        setTokenUri(_currentLicenseBundleId, _mintURI);
        _mint(_to, _currentLicenseBundleId, _amount, _erc721Reference);
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
}
