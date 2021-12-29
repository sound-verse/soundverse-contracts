// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC721.sol";
import "./SoundVerseERC1155.sol";
import "./SoundVerseToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "../contracts/PercentageUtils.sol";

contract MarketContract is Ownable, ReentrancyGuard, PercentageUtils {
    using SafeMath for uint256;
    address payable internal admin;
    SoundVerseToken public tokenContract;
    PercentageUtils internal percentageUtils;

    uint256 public constant SERVICE_FEES_TIER_1 = 3000;
    uint256 public constant SERVICE_FEES_TIER_2 = 4000;
    uint256 public constant SERVICE_FEES_TIER_3 = 5000;

    mapping(address => uint256) public userFees;

    event SoldNFT(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _purchasePrice
    );

    event Withdrawal(address _payee, uint256 _amount);

    constructor(
        SoundVerseToken _tokenContract,
        address _percentageUtilsAddress
    ) {
        //Assign admin
        admin = payable(owner());
        //Token contract
        tokenContract = _tokenContract;
        //Utils contract
        percentageUtils = PercentageUtils(_percentageUtilsAddress);
        
    }

    function purchaseTokens(
        address _from,
        uint256 _tokenId,
        uint256 _tokenPrice,
        uint256 _amountOfTokens,
        address _nftContractAddress
    ) public payable nonReentrant {
        //Require tokenPrice to be greater than zero
        require(_tokenPrice > 0, "Price must be greater than zero");

        //Total amount to pay with service fees
        uint256 purchasePriceWithServiceFee = msg.value;
        //Amount to pay without service fees
        uint256 netPurchasePrice = _tokenPrice.mul(_amountOfTokens);

        //Requires that the contract has enough tokens
        require(
            getThisAddressTokenBalance(_from, _tokenId, _nftContractAddress) >= _amountOfTokens,
            "Can not buy more than available"
        );

        // Calculate fees and requires to pay services fees on top
        uint256 purchaseFeesFromUser = currentFeesTierFromUser(_from);
        uint256 calculatedFees = PercentageUtils.percentageCalculatorDiv(
            netPurchasePrice,
            purchaseFeesFromUser
        );

        require(
            purchasePriceWithServiceFee ==
                calculateAmountToPay(
                    _tokenPrice,
                    _amountOfTokens,
                    calculatedFees
                ),
            "Not the correct price amount or service fees not paid"
        );

        extractFeesAndTransfer(purchasePriceWithServiceFee, purchaseFeesFromUser);

        //NFT transfer
        IERC1155(_nftContractAddress).safeTransferFrom(
            _from,
            _msgSender(),
            _tokenId,
            _amountOfTokens,
            _msgData()
        );

        emit SoldNFT(
            _from,
            _msgSender(),
            _tokenId,
            _amountOfTokens,
            netPurchasePrice
        );
    }

    //Returns this addresses balance
    function getThisAddressTokenBalance(address _from, uint256 _tokenId, address _nftContractAddress)
        public
        view
        returns (uint256)
    {
        return IERC1155(_nftContractAddress).balanceOf(_from, _tokenId);
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
        uint256 fees = PercentageUtils.percentageCalculatorDiv(
            _orderAmount,
            _feesPercentage
        );
        admin.transfer(msg.value);
        emit Withdrawal(admin, fees);
    }

    function calculateAmountToPay(
        uint256 _tokenPrice,
        uint256 _amountOfTokens,
        uint256 _fees
    ) internal pure returns (uint256) {
        return _tokenPrice.mul(_amountOfTokens).add(_fees);
    }
}
