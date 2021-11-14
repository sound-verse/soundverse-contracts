// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC1155.sol";
import "./SoundVerseToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract NftTokenSale is Ownable, ReentrancyGuard {
    address payable internal admin;
    SoundVerseERC1155 public nftContract;
    SoundVerseToken public tokenContract;

    uint256 public constant SERVICE_FEES_TIER_1 = 3;
    uint256 public constant SERVICE_FEES_TIER_2 = 4;
    uint256 public constant SERVICE_FEES_TIER_3 = 5;

    mapping(address => uint256) public userFees;

    event SoldNFT(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _purchasePrice
    );

    event Withdrawal(address _payee, uint256 _amount);

    constructor(SoundVerseERC1155 _nftContract, SoundVerseToken _tokenContract)
    {
        //Assign admin
        admin = payable(owner());
        //NFT contract
        nftContract = _nftContract;
        //Token contract
        tokenContract = _tokenContract;
    }

    function purchaseTokens(
        address _from,
        uint256 _tokenId,
        uint256 _tokenPrice,
        uint256 _amountOfTokens
    ) public payable nonReentrant {
        //Require tokenPrice to be greater than zero
        require(_tokenPrice > 0, "Price must be greater than zero");

        uint256 purchasePrice = msg.value;

        // Calculate fees and requires to pay services fees on top
        uint256 purchaseFeesFromUser = currentFeesTierFromUser(_from);
        uint256 calculatedFees = calculateFees(purchasePrice, purchaseFeesFromUser);

        console.log("purchase price: ", purchasePrice);
        console.log("calculated fees: ", calculatedFees);

        require(
            purchasePrice ==
                SafeMath.mul(_tokenPrice, _amountOfTokens) +
                    calculatedFees,
            "Not the correct price amount or service fees not paid"
        );

        //Requires that the contract has enough tokens
        require(
            getThisAddressTokenBalance(_from, _tokenId) >= _amountOfTokens,
            "Can not buy more than available"
        );

        extractFeesAndTransfer(purchasePrice, purchaseFeesFromUser);

        uint256 netPurchasePrice = calculateAmountToTransfer(
            purchasePrice,
            purchaseFeesFromUser
        );

        nftContract.safeTransferFrom(
            _from,
            _msgSender(),
            _tokenId,
            netPurchasePrice,
            _msgData()
        );

        //Trigger sell event
        emit SoldNFT(
            _from,
            _msgSender(),
            _tokenId,
            _amountOfTokens,
            netPurchasePrice
        );
    }

    //Returns this addresses balance
    function getThisAddressTokenBalance(address _from, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return nftContract.balanceOf(_from, _tokenId);
    }

    // Calculate service fee tier
    function currentFeesTierFromUser(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 tokenAmount = tokenContract.balanceOf(_userAddress);
        if (tokenAmount > 1000000) {
            return SERVICE_FEES_TIER_1;
        } else if (tokenAmount >= 500000 && tokenAmount < 1000000) {
            return SERVICE_FEES_TIER_2;
        } else {
            return SERVICE_FEES_TIER_3;
        }
    }

    //Service Fee extraction
    function extractFeesAndTransfer(
        uint256 _orderAmount,
        uint256 _feesPercentage
    ) public payable {
        uint256 fees = calculateFees(_orderAmount, _feesPercentage);
        admin.transfer(msg.value);
        emit Withdrawal(admin, fees);
    }

    function calculateFees(uint256 _orderAmount, uint256 _feesTier)
        public
        pure
        returns (uint256)
    {
        uint256 feesPercentage;
        ( , feesPercentage) = SafeMath.tryDiv(_feesTier, 10);

        uint256 fees = SafeMath.mul(_orderAmount, feesPercentage);
        
        return fees;
    }

    function calculateAmountToTransfer(
        uint256 _orderAmount,
        uint256 _feesTier
    ) public pure returns (uint256) {
        uint256 feesPercentage;
        ( , feesPercentage) = SafeMath.tryDiv(_feesTier, 10);
        
        uint256 fees = SafeMath.mul(
            _orderAmount,
            feesPercentage
        );

        return SafeMath.sub(_orderAmount, fees);
    }
}
