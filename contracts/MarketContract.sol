// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SoundVerseERC721.sol";
import "./SoundVerseERC1155.sol";
import "./SoundVerseToken.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../contracts/libs/PercentageUtils.sol";

contract MarketContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    //Contracts
    SoundVerseToken public tokenContract;

    address payable admin;
    uint256 listingPrice = 0.025 ether;

    // Service fee tiers
    uint256 public constant SERVICE_FEES_TIER_1 = 3000;
    uint256 public constant SERVICE_FEES_TIER_2 = 4000;
    uint256 public constant SERVICE_FEES_TIER_3 = 5000;

    constructor(SoundVerseToken _tokenContract)
    {
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
        uint256 amount;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        uint256 amount,
        bool sold
    );

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    mapping(address => uint256) public userFees;

    event Withdrawal(address _payee, uint256 _amount);

    // This function places an item for sale on the marketplace
    function createMarketItem(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _amountOfTokens,
        uint256 _tokenPrice
    ) public payable nonReentrant {
        //Require tokenPrice to be greater than zero
        require(_tokenPrice > 0.1 ether, "Price must be greater than 0.1");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            _nftContractAddress,
            _tokenId,
            payable(_msgSender()),
            payable(address(0)),
            _tokenPrice,
            _amountOfTokens,
            false
        );

        // address _nftContractAddress = libraryModifier.getERC1155State();

        if (_amountOfTokens == 1) {
            // ERC721 - Master
            IERC721(_nftContractAddress).transferFrom(
                _msgSender(),
                address(this),
                _tokenId
            );
        } else {
            //ERC1155 - Licenses
            IERC1155(_nftContractAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenId,
                _amountOfTokens,
                _msgData()
            );
        }

        emit MarketItemCreated(
            itemId,
            _nftContractAddress,
            _tokenId,
            _msgSender(),
            address(0),
            _tokenPrice,
            _amountOfTokens,
            false
        );
    }

    // Creates the sale of a marketplace item
    // Transfers ownership of the item, as well as funds between parties
    function purchaseTokens(
        uint256 _itemId,
        uint256 _amountOfTokens,
        address _nftContractAddress
    ) public payable nonReentrant {
        uint256 price = idToMarketItem[_itemId].price;
        uint256 tokenId = idToMarketItem[_itemId].tokenId;

        // Total amount to pay with service fees
        uint256 purchasePriceWithServiceFee = msg.value;
        // Amount to pay without service fees
        uint256 netPurchasePrice = price.mul(_amountOfTokens);

        // Calculate fees and requires to pay services fees on top
        uint256 purchaseFeesFromUser = currentFeesTierFromUser(_msgSender());
        uint256 calculatedFees = PercentageUtils.percentageCalculatorDiv(
            netPurchasePrice,
            purchaseFeesFromUser
        );

        require(
            purchasePriceWithServiceFee ==
                calculateAmountToPay(price, _amountOfTokens, calculatedFees),
            "Not the correct price amount or service fees not paid"
        );

        extractFeesAndTransfer(
            purchasePriceWithServiceFee,
            purchaseFeesFromUser
        );

        require(
            msg.value == price,
            "Please submit the asking price in order to complete purchase"
        );

        // Fund transfer to the seller
        idToMarketItem[_itemId].seller.transfer(msg.value);

        // NFT transfer to the buyer
        if (_amountOfTokens == 1) {
            //ERC-721 - Master
            IERC721(_nftContractAddress).transferFrom(
                address(this),
                _msgSender(),
                tokenId
            );
        } else {
            //ERC1155 - Licenses
            IERC1155(_nftContractAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenId,
                _amountOfTokens,
                _msgData()
            );
        }

        idToMarketItem[_itemId].owner = payable(_msgSender());
        idToMarketItem[_itemId].sold = true;
        _itemsSold.increment();

        // ListingPrice transfer to Marketplace
        payable(admin).transfer(listingPrice);
    }

    // Returns all unsold listed items
    function fetchListedItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
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

    // Service Fee extraction
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
