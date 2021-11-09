// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NftTokenSale is Ownable, ReentrancyGuard {
    address payable internal admin;
    SoundVerseERC1155 public nftContract;
    uint256 public tokenPrice;

    event SoldNFT(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _purchasePrice
    );

    event Withdrawal(address _payee, uint256 _amount);

    constructor(SoundVerseERC1155 _nftContract) {
        //Assign admin
        admin = payable(owner());
        //NFT contract
        nftContract = _nftContract;
    }

    function purchaseTokens(
        address _from,
        uint256 _tokenId,
        uint256 _tokenPrice,
        uint256 _amountOfTokens
    ) public payable nonReentrant {
        //Require tokenPrice to be greater than zero
        require(_tokenPrice > 0, "Price must be greater than zero");

        //Requires that the correct amount is bought
        uint256 purchasePrice = msg.value;
        require(
            purchasePrice == SafeMath.mul(_tokenPrice, _amountOfTokens),
            "Not the correct price amount"
        );

        //Requires that the contract has enough tokens
        require(
            getThisAddressTokenBalance(_from, _tokenId) >= _amountOfTokens,
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
        emit SoldNFT(_from, _msgSender(), _tokenId, _amountOfTokens, purchasePrice);
    }

    //Returns this addresses balance
    function getThisAddressTokenBalance(address _from, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return nftContract.balanceOf(_from, _tokenId);
    }

    function setCurrentPrice(uint256 _currentPrice) public {
        require(_currentPrice > 0, "Current price must be greater than zero");
        tokenPrice = _currentPrice;
    }

    //Withdraw funds
    function withdrawTo() public payable onlyOwner {
        uint256 amountToWithdraw = msg.value;
        require(amountToWithdraw > 0, "Not able to withdraw zero");
        
        emit Withdrawal(admin, amountToWithdraw);
    }
}
