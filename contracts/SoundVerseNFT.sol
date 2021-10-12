// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoundVerseNFT is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    //Constants and variables
    uint256 public constant MAX_ELEMENTS = 1000;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant START_AT = 1;

    uint256 internal fee;

    //Events
    event NewMintEvent(uint256 indexed id);

    constructor() ERC721("SoundVerse", "SVMT") {
        fee = 0.1 * 10**18;
    }

    // Keeps track of total minted nfts
    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    // Minting functions
    function createUnpublishedItem(
        uint256[] memory _tokensId,
        string memory tokenURI
    ) public payable {
        uint256 total = totalToken();
        require(total + _tokensId.length <= MAX_ELEMENTS, "Max limit of NFTs");
        require(msg.value >= price(_tokensId.length), "Value below price");

        address unpublishedOwner = _msgSender();

        for (uint8 i = 0; i < _tokensId.length; i++) {
            _mintItem(unpublishedOwner, _tokensId[i]);
            _setTokenURI(_tokensId[i], tokenURI);
        }

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

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }
}
