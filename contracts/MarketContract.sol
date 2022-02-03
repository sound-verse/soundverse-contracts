// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC721.sol";
import "./SoundVerseERC1155.sol";
import "./SoundVerseToken.sol";
import "./CommonUtils.sol";
import "./libs/PercentageUtils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address payable internal admin;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    // Constants
    string public constant SV721 = "SoundVerseERC721";
    string public constant SV1155 = "SoundVerseERC1155";
    uint256 public constant LISTING_PRICE = 0.025 ether;
    uint256 public constant PURCHASE_FEES = 5000;

    //Contracts
    SoundVerseToken public tokenContract;
    CommonUtils public commonUtils;

    constructor(SoundVerseToken _tokenContract) {
        admin = payable(owner());
        tokenContract = _tokenContract;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    /**
     * @dev Event to be triggered after successful withdrawal
     */
    event Withdrawal(address _payee, uint256 _amount);

    /**
     * @dev Creates the sale of a marketplace item, transfers ownership of the item, as well as funds between parties
     * @param _contractType SoundVerse contract standard to list (SoundVerseERC721, SoundVerseERC1155)
     * @param _itemId ID of item to be purchased
     */
    function purchaseTokens(string memory _contractType, uint256 _itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[_itemId].price;
        uint256 tokenId = idToMarketItem[_itemId].tokenId;

        // Calculate fees and requires to pay services fees on top
        uint256 calculatedFees = PercentageUtils.percentageCalculatorDiv(
            price,
            PURCHASE_FEES
        );

        // Total amount to pay with service fees
        uint256 purchasePriceWithServiceFee;
        require(
            purchasePriceWithServiceFee ==
                calculateAmountToPay(price, calculatedFees),
            "Not the correct price amount or service fees not paid"
        );

        require(
            msg.value == price,
            "Please submit the asking price in order to complete purchase"
        );

        // Fund transfer to the seller
        idToMarketItem[_itemId].seller.transfer(msg.value);

        // NFT transfer to the buyer
        address _nftContractAddress;
        if (commonUtils.compareStrings(_contractType, SV721)) {
            _nftContractAddress = commonUtils.getContractAddressFrom(SV721);
            //ERC-721 - Master
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                _msgSender(),
                tokenId
            );
        } else {
            _nftContractAddress = commonUtils.getContractAddressFrom(SV1155);
            //ERC1155 - Licenses
            IERC1155(_nftContractAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenId,
                1,
                _msgData()
            );
        }

        idToMarketItem[_itemId].owner = payable(_msgSender());
        idToMarketItem[_itemId].sold = true;
        _itemsSold.increment();

        withdrawFees(calculatedFees);
    }

    /**
     * @dev Service fees extraction and withdrawal
     * @param _calculatedFees Amount of fees to pay to marketplace
     */
    function withdrawFees(uint256 _calculatedFees) public payable {
        payable(admin).transfer(_calculatedFees);
        emit Withdrawal(admin, _calculatedFees);
    }

    /**
     * @dev Calculates total order amount
     * @param _tokenPrice Amount of fees to pay to marketplace
     * @param _fees Purchase fees
     * @return uint256 Total order amount
     */
    function calculateAmountToPay(uint256 _tokenPrice, uint256 _fees)
        internal
        pure
        returns (uint256)
    {
        return _tokenPrice.mul(1).add(_fees);
    }
}
