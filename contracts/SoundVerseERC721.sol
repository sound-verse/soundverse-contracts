// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoundVerseERC721 is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    //Constants and variables
    Counters.Counter private _tokenIdTracker;
    uint256 public itemPrice;
    uint256 public fee;
    mapping (string => bool) public allowedDomains;

    //Events
    event NewMintEvent(uint256 indexed id);

    constructor() ERC721("SoundVerse", "SVMT") {}

    // Minting functions
    function createUnpublishedItem(string memory tokenURI) public payable {
        require( allowedDomains[tokenURI], "TokenURI must be allowed");

        address unpublishedOwner = _msgSender();

        uint256 currentTokenId = _tokenIdTracker.current();

        _mintItem(unpublishedOwner, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);
    }

    function _mintItem(address _to, uint256 _tokenId) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);

        emit NewMintEvent(_tokenId);
    }

    //Burning function
    function burnUnpublishedItem(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    //utils
    // Keeps track of total minted nfts
    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function addAllowedURI(string memory _allowedURI) public onlyOwner {
        allowedDomains[_allowedURI] = true;
    }
}
