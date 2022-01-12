// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoundVerseERC721 is
    AccessControlEnumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    //Constants and variables
    Counters.Counter private _tokenIdTracker;
    address public marketplaceAddress;
    uint256 public itemPrice;
    uint256 public fee;
    mapping(string => bool) public allowedDomains;

    //Events
    event NewMintEvent(uint256 indexed id);

    constructor(address _marketplaceAddress)
        ERC721("SoundVerseOriginal", "SVO")
    {
        marketplaceAddress = _marketplaceAddress;
    }

    /**
     * @dev Mint Master
     *
     * Function to create Master NFT
     * Sets tokenURI
     * Approves the Marketplace to handle the Master
     *
     */
    function createMasterItem(string memory tokenURI) public payable {
        require(allowedDomains[tokenURI], "TokenURI must be allowed");

        uint256 currentTokenId = _tokenIdTracker.current();

        mintItem(_msgSender(), currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);
        setApprovalForAll(marketplaceAddress, true);
    }

    /**
     * @dev Mint Master
     *
     * Increments the TokenId
     * Mints from Interface
     * Emits Mint Event
     *
     */
    function mintItem(address _to, uint256 _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit NewMintEvent(_tokenId);
    }

    /**
     * @dev Burn tokens
     *
     * lets the owner of the contract burn tokens
     * Needs tokenId
     */
    function burnUnpublishedItem(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    /**
     * @dev Total of tokens
     *
     * Keeps track of total minted nfts
     *
     */
    function totalTokens() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev Allowed URIs
     *
     * Adds allowed URIs to the mapping
     * Must be contract owner to use it.
     */
    function addAllowedURI(string memory _allowedURI) public onlyOwner {
        allowedDomains[_allowedURI] = true;
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
