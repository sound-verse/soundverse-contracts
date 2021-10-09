// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoundVerseNFT is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //Constants and variables
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant START_AT = 1;

    Counters.Counter private _tokenIds;

    uint256 internal fee;

    //Events
    event NewMintEvent(uint256 indexed id);

    constructor() ERC721("SoundVerse", "SVMT") {
       fee = 0.1 * 10 ** 18;
    }

    // Minting functions
    function createUnpublishedItem(string memory tokenURI) public payable {
        require(msg.value >= PRICE, "Value below price");
    
        address unpublishedOwner = _msgSender();
        uint256 newItemId = _tokenIds.current();

        _mintItem(unpublishedOwner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        setApprovalForAll(unpublishedOwner, true);
    }

    function _mintItem(address _to, uint256 _tokenId) private {

        _tokenIds.increment();
        _safeMint(_to, _tokenId);

        emit NewMintEvent(_tokenId);
    }

    //Burning function
    function burnUnpublishedItem(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

}