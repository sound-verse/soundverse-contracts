// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./MarketContract.sol";
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
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant MAX_SUPPLY = 500;

    address public marketContractAddress;

    mapping(uint256 => string) private _uris;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(address _marketContractAddress) ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        marketContractAddress = _marketContractAddress;
    }

    event RPCCall(string uri, uint256 amount);

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
    function mint(
        address to,
        uint256 id,
        string memory _mintUri,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(bytes(_mintUri).length != 0, "URI can not be empty");
        require(amount <= MAX_SUPPLY, "Max supply exceeded");

        setTokenUri(id, _mintUri);

        setApprovalForAll(marketContractAddress, true);

        emit RPCCall(_mintUri, amount);

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        string[] memory _batchMintUris,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            ids.length == _batchMintUris.length,
            "Ids and URIs length mismatch"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                bytes(_batchMintUris[i]).length != 0,
                "There is an empty URI on the list"
            );
            require(amounts[i] <= MAX_SUPPLY, "Max supply exceeded");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            setTokenUri(ids[i], _batchMintUris[i]);
        }

        setApprovalForAll(marketContractAddress, true);

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
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
