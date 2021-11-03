// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NftTokenSale is Ownable, ReentrancyGuard {
    address internal admin;
    SoundVerseERC1155 public nftContract;
    uint256 public tokenPrice;

    event SoldNFT(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _amount
    );

    event Withdrawal(address _payee, uint256 _amount);

    constructor(SoundVerseERC1155 _nftContract, uint256 _tokenPrice) {
        //Assign admin
        admin = msg.sender;
        require(_tokenPrice > 0, "Price must be greater than zero");
        //NFT contract
        nftContract = _nftContract;
        //NFT price
        tokenPrice = _tokenPrice;
    }

    function purchaseTokens(
        address _from,
        uint256 _tokenId,
        uint256 _amountOfTokens
    ) public payable nonReentrant {
        //Requires that the correct amount is bought
        require(
            msg.value == SafeMath.mul(_amountOfTokens, tokenPrice),
            "Not the correct price amount"
        );

        //Requieres the correct pricr
        require(msg.value >= tokenPrice, "The price does not match");

        //Requires that the contract has enough tokens
        require(
            getThisAddressTokenBalance(_tokenId) >= _amountOfTokens,
            "Can not buy more than available"
        );

        nftContract.safeTransferFrom(
            _from,
            _msgSender(),
            _tokenId,
            _amountOfTokens,
            _msgData()
        );

        //Trigger sell event
        emit SoldNFT(_from, _msgSender(), _tokenId, _amountOfTokens);
    }

    //Withdraw funds
    function withdrawTo(address payable _payee, uint256 _amount) public onlyOwner {
        require(_payee != address(0) && _payee != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        _payee.transfer(_amount);
        emit Withdrawal(_payee, _amount);
    }

    //Returns this addresses balance
    function getThisAddressTokenBalance(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return nftContract.balanceOf(address(this), _tokenId);
    }

    function setCurrentPrice(uint256 _currentPrice) public onlyOwner {
        require(_currentPrice > 0, "Current price must be greater than zero");
        tokenPrice = _currentPrice;
    }
}
