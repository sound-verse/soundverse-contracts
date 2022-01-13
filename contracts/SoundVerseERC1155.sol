// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
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
     */
    constructor(address _marketplaceAddress) ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        marketplaceAddress = _marketplaceAddress;
    }

    /**
     * @dev Returns the actual `baseURI` for token type `id`.
     *
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    /**
     * @dev Sets token URI for token type `id`.
     *
     */
    function setTokenUri(uint256 tokenId, string memory _uri) internal {
        require(bytes(_uris[tokenId]).length == 0, "Cannot set uri twice");
        _uris[tokenId] = _uri;
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     */
    function mintLicenses(
        address to,
        string memory _mintUri,
        uint256 amount,
        bytes memory erc721Reference
    ) private {
        uint256 currentLicenseBundleId = _licenseBundleId.current();
        require(bytes(_mintUri).length != 0, "URI can not be empty");
        require(amount >= MIN_SUPPLY, "Supply must be greater than 2");

        setApprovalForAll(marketplaceAddress, true);

        mint(to, currentLicenseBundleId, _mintUri, amount, erc721Reference);
    }

    /**
     * @dev Mint Master
     *
     * Increments the TokenId
     * Sets the token URI for tokendId
     * Mints from Interface
     *
     */
    function mint(
        address _to,
        uint256 _currentLicenseBundleId,
        string memory _mintUri,
        uint256 amount,
        bytes memory erc721Reference
    ) private {
        _licenseBundleId.increment();

        setTokenUri(_currentLicenseBundleId, _mintUri);
        _mint(_to, _currentLicenseBundleId, amount, erc721Reference);
    }

    /**
     * @dev Total of tokens
     *
     * Keeps track of total minted nfts
     *
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
