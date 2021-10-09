// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SoundVerseNFT is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public minterAddress;

    constructor(address minter) ERC721("SoundVerse Music Tokens", "SVMT") {
        minterAddress = minter;
    }

    function createUnpublishedItem(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(minterAddress, true);
        return newItemId;
    }

    function burnUnpublishedItem(uint256 tokenId) public {
        _burn(tokenId);
    }

    

}