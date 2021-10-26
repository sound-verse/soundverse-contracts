// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract SoundVerseTokenSale is Ownable, ReentrancyGuard {
    address internal admin;
    SoundVerseToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    constructor(SoundVerseToken _tokenContract, uint256 _tokenPrice) {
        //Assign an admin
        admin = msg.sender;
        //Token contract
        tokenContract = _tokenContract;
        //Token price
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable nonReentrant {
        //Requires that the correct amount is bought
        require(
            msg.value == SafeMath.mul(_numberOfTokens, tokenPrice),
            "Not the correct price amount"
        );
        //Requires that the contract has enough tokens
        require(
            getThisAddressTokenBalance() >= _numberOfTokens,
            "Can not buy more than available"
        );
        //Requires that a transfer is successful
        require(
            tokenContract.transfer(msg.sender, _numberOfTokens),
            "Transfer failed"
        );
        //Keep track of sold tokens
        tokensSold += _numberOfTokens;
        //Trigger sell event
        emit Sell(msg.sender, _numberOfTokens);
    }

    //End token sale
    function endSale() public onlyOwner {
        //Require admin scope
        require(msg.sender == admin, "Not allowed to end sale");
        //Transfer remaining tokens back to admin
        require(
            tokenContract.transfer(admin, getThisAddressTokenBalance()),
            "Failed transfer remains to admin"
        );
        //Destroy contract
        selfdestruct(payable(admin));
    }

    //Returns this addresses balance
    function getThisAddressTokenBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }
}
