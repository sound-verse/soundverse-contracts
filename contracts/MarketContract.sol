// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma abicoder v2;

import "./CommonUtils.sol";
import "./libs/PercentageUtils.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/ILicense.sol";
import "./RoyaltyManager.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "hardhat/console.sol";

contract MarketContract is
  AccessControlEnumerable,
  EIP712,
  Ownable,
  ReentrancyGuard,
  RoyaltyManager
{
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  address payable internal admin;
  Counters.Counter private itemsSold;
  uint256 public _serviceFees;

  // Constants
  string internal constant SIGNING_DOMAIN = "SVVoucher";
  string internal constant SIGNATURE_VERSION = "1";
  string internal constant MASTER = "Master";
  string internal constant LICENSE = "License";

  // Mappings
  mapping(bytes => bool) public isVoucherInvalid;
  mapping(bytes => uint256) public voucherAmountSold;

  //Contracts
  ICommonUtils public commonUtils;
  ILicense public licensesContract;
  IMaster public masterContract;
  address licenseAddress;
  address masterAddress;

  // Events
  event Withdrawal(address _payee, uint256 _amount);
  event UnlistedNFT(bytes signature);
  event RedeemedItem(bytes signature, uint256 soldAmount);
  event RedeemedItemSecondarySale(bytes signature, uint256 soldAmount);

  // Vouchers
  struct MintVoucher {
    uint256 price;
    string tokenUri;
    uint256 supply;
    uint256 maxSupply;
    bool isMaster;
    bytes signature;
    string currency;
    uint96 royaltyFeeMaster;
    uint96 royaltyFeeLicense;
    uint96 creatorOwnerSplit;
    uint256 validUntil;
  }

  struct SaleVoucher {
    address nftContractAddress;
    uint256 price;
    string tokenUri;
    uint256 supply;
    bool isMaster;
    bytes signature;
    string currency;
    uint256 validUntil;
  }

  // Constructor
  constructor(address _commonUtilsAddress)
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
  {
    admin = payable(owner());
    _serviceFees = 3000;
    commonUtils = ICommonUtils(_commonUtilsAddress);
  }

  /**
   * @dev Initializes the contracts with respective interfaces
   */
  function initializeContracts() internal {
    licenseAddress = commonUtils.getContractAddressFrom(LICENSE);
    masterAddress = commonUtils.getContractAddressFrom(MASTER);
    licensesContract = ILicense(licenseAddress);
    masterContract = IMaster(masterAddress);
  }

  /**
   * @dev Creates the sale of a marketplace item, transfers ownership of the item, as well as funds between parties
   * @param _buyer The address of the account which will receive the NFT upon success.
   * @param _seller The address of the account which will sell the NFT upon success.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _mintVoucher A signed MintVoucher that describes the NFT to be redeemed.
   */
  function redeemItem(
    address _buyer,
    address _seller,
    uint256 _amountToPurchase,
    MintVoucher calldata _mintVoucher
  ) public payable nonReentrant {
    console.log("REDEEMITEM STARTING....");
    require(
      isVoucherInvalid[_mintVoucher.signature] == false,
      "RedeemItem: Voucher invalid"
    );
    require(
      _mintVoucher.validUntil <= block.timestamp,
      "RedeemItem: Timestamp exceeded"
    );

    require(
      _mintVoucher.supply >=
        _amountToPurchase.add(voucherAmountSold[_mintVoucher.signature]),
      "redeemItem: Not enough supply"
    );

    initializeContracts();

    uint256 purchasePrice;
    address nftContractAddress;
    if (_mintVoucher.isMaster == true) {
      nftContractAddress = masterAddress;
    } else {
      nftContractAddress = licenseAddress;
    }

    address _signer = _verify(_mintVoucher);
    purchasePrice = approvePurchase(
      _seller,
      _signer,
      _mintVoucher.price,
      _mintVoucher.isMaster,
      _amountToPurchase
    );

    // Mints an NFT if it doesnt exist at the time of buying (Lazy minting)
    uint256 tokenId = masterContract.tokenIdForURI(_mintVoucher.tokenUri);

    require(tokenId == 0, "TokenId must not exist");
    sellItemOnPrimarySale(
      purchasePrice,
      _signer,
      _buyer,
      _amountToPurchase,
      _mintVoucher
    );

    uint256 calculatedServiceFees = calculateServiceFees(
      _mintVoucher.price,
      serviceFees()
    );

    voucherAmountSold[_mintVoucher.signature] = voucherAmountSold[_mintVoucher.signature].add(_amountToPurchase);

    emit RedeemedItem(_mintVoucher.signature, _amountToPurchase);

    if(voucherAmountSold[_mintVoucher.signature] == _mintVoucher.supply){
        isVoucherInvalid[_mintVoucher.signature] = false;
    }

    withdrawFees(calculatedServiceFees);
  }

  /**
   * @dev Creates the sale of a marketplace item, transfers ownership of the item, as well as funds between parties
   * @param _buyer The address of the account which will receive the NFT upon success.
   * @param _seller The address of the account which will sell the NFT upon success.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _saleVoucher A signed SaleVoucher that describes the NFT to be redeemed.
   */
  function redeemItemSecondarySale(
    address _buyer,
    address _seller,
    uint256 _amountToPurchase,
    SaleVoucher calldata _saleVoucher
  ) public payable nonReentrant {
    console.log("REDEEMITEM STARTING....");
    require(
      isVoucherInvalid[_saleVoucher.signature] == false,
      "RedeemItem: Voucher invalid"
    );

    require(
      _saleVoucher.validUntil <= block.timestamp,
      "RedeemItem: Timestamp exceeded"
    );

    require(
      _saleVoucher.supply >=
        _amountToPurchase.add(voucherAmountSold[_saleVoucher.signature]),
      "redeemItemSecondarySale: Not enough supply"
    );

    uint256 purchasePrice;

    address _signer = _verify(_saleVoucher);
    purchasePrice = approvePurchase(
      _seller,
      _signer,
      _saleVoucher.price,
      _saleVoucher.isMaster,
      _amountToPurchase
    );

    // Mints an NFT if it doesnt exist at the time of buying (Lazy minting)
    uint256 tokenId = masterContract.tokenIdForURI(_saleVoucher.tokenUri);
    sellItemOnSecondarySale(
      tokenId,
      purchasePrice,
      _signer,
      _buyer,
      _amountToPurchase,
      _saleVoucher
    );

    uint256 calculatedServiceFees = calculateServiceFees(
      _saleVoucher.price,
      serviceFees()
    );

    voucherAmountSold[_saleVoucher.signature] = voucherAmountSold[_saleVoucher.signature].add(_amountToPurchase);

    emit RedeemedItemSecondarySale(_saleVoucher.signature, _amountToPurchase);

    if(voucherAmountSold[_saleVoucher.signature] == _saleVoucher.supply){
        isVoucherInvalid[_saleVoucher.signature] = false;
    }

    withdrawFees(calculatedServiceFees);
  }

  /**
   * @dev Function called for lazy minting and primary sales
   * @param purchasePrice Price of the NFT to purchase
   * @param _signer The address of the account which will sell the NFT upon success.
   * @param _buyer The address of the account which will receive the NFT upon success.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _mintVoucher A signed MintVoucher that describes the NFT to be redeemed.
   */
  function sellItemOnPrimarySale(
    uint256 purchasePrice,
    address _signer,
    address _buyer,
    uint256 _amountToPurchase,
    MintVoucher calldata _mintVoucher
  ) internal {
    console.log("CREATE MASTER ITEM about to be called....");
    uint256 tokenId = masterContract.createMasterItem(
      _signer,
      _mintVoucher.tokenUri,
      _mintVoucher.maxSupply
    );

    _setTokenRoyaltySplit(
      tokenId,
      _mintVoucher.royaltyFeeMaster,
      _mintVoucher.royaltyFeeLicense,
      _mintVoucher.creatorOwnerSplit
    );

    payAndTransfer(
      tokenId,
      _buyer,
      _signer,
      purchasePrice,
      _amountToPurchase,
      _mintVoucher.isMaster
    );
  }

  /**
   * @dev Function called for secondary sales
   * @param _tokenId ID of the NFT to purchase
   * @param purchasePrice Price of the NFT to purchase
   * @param _signer The address of the account which will sell the NFT upon success.
   * @param _buyer The address of the account which will receive the NFT upon success.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _saleVoucher A signed SaleVoucher that describes the NFT to be redeemed.
   */
  function sellItemOnSecondarySale(
    uint256 _tokenId,
    uint256 purchasePrice,
    address _signer,
    address _buyer,
    uint256 _amountToPurchase,
    SaleVoucher calldata _saleVoucher
  ) internal {
    console.log("PURCHASENFT: Royalty Info STARTING....");

    payAndTransfer(
      _tokenId,
      _buyer,
      _signer,
      purchasePrice,
      _amountToPurchase,
      _saleVoucher.isMaster
    );
  }

  /**
   * @dev Monetary checklist for purchasing NFTs, will return purchase price
   * @param _seller The address of the account which will sell the NFT upon success.
   * @param _signer The address of the account which will sell the NFT upon success.
   * @param _price Price to be paid for NFT.
   * @param _isMaster Indicates if NFT is master.
   * @param _amountToPurchase Amount of items to be purchased

   */
  function approvePurchase(
    address _seller,
    address _signer,
    uint256 _price,
    bool _isMaster,
    uint256 _amountToPurchase
  ) internal returns (uint256) {
    uint256 totalPurchase = msg.value;
    require(totalPurchase > 0, "No amount being transferred");

    // make sure that the signer of the Voucher is the seller
    require(_seller == _signer, "Signature invalid");

    uint256 purchaseFees = serviceFees();

    uint256 calculatedServiceFees = calculateServiceFees(_price, purchaseFees);

    // Total amount to pay with service fees
    uint256 purchasePriceWithServiceFee;
    if (_isMaster == true) {
      purchasePriceWithServiceFee = calculateAmountToPay(
        _price,
        calculatedServiceFees,
        1
      );
    } else {
      purchasePriceWithServiceFee = calculateAmountToPay(
        _price,
        calculatedServiceFees,
        _amountToPurchase
      );
    }
    uint256 purchasePrice = purchasePriceWithServiceFee.sub(
      calculatedServiceFees
    );

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(
      totalPurchase >= purchasePriceWithServiceFee,
      "Insufficient funds to redeem"
    );

    return purchasePrice;
  }

  /**
   * @dev Sets payment and transferring of the NFT
   * @param _tokenId TokenId of the NFT
   * @param _buyer The address of the buyer of the NFT
   * @param _signer The address of the account which will sell the NFT upon success
   * @param _purchasePrice Price to be paid by the buyer
   * @param _amountToPurchase Amount of items to be purchased
   * @param _isMaster Is a Master nft or is a License
   */
  function payAndTransfer(
    uint256 _tokenId,
    address _buyer,
    address _signer,
    uint256 _purchasePrice,
    uint256 _amountToPurchase,
    bool _isMaster
  ) internal {
    require(_tokenId != 0, "NFT could not be minted");
    // Transfer NFTS
    uint256 licensesAmountFromSigner;

    uint256 royaltyAmountCreator;
    uint256 royaltyAmountOwner;
    uint256 restSalePrice;
    if (_isMaster == true) {
      (royaltyAmountCreator, restSalePrice) = _royaltySplitMaster(
        _tokenId,
        _purchasePrice
      );

      address creator = masterContract._getCreator(_tokenId);

      payable(creator).transfer(royaltyAmountCreator);

      //transfer money to seller
      payable(_signer).transfer(restSalePrice);

      // Transfer master and license(s) to buyer
      masterContract.transferMaster(_signer, _buyer, _tokenId);
      licensesAmountFromSigner = licensesContract.licensesBalanceOf(
        _signer,
        _tokenId
      );
      licensesContract.transferLicenses(
        _signer,
        _buyer,
        _tokenId,
        licensesAmountFromSigner
      );
      itemsSold.increment();
    } else {
      (
        royaltyAmountCreator,
        royaltyAmountOwner,
        restSalePrice
      ) = _royaltySplitLicense(_tokenId, _purchasePrice);

      address creator = licensesContract._getCreator(_tokenId);
      address owner = masterContract._getOwner(_tokenId);

      payable(creator).transfer(royaltyAmountCreator);
      payable(owner).transfer(royaltyAmountOwner);

      //transfer money to seller
      payable(_signer).transfer(restSalePrice);

      // Transfer license(s) to buyer
      licensesContract.transferLicenses(
        _signer,
        _buyer,
        _tokenId,
        _amountToPurchase
      );
    }
  }

  /**
   * @dev Calculates the services fees
   * @param _mintVoucherPrice Price to be paid by the buyer
   * @param purchaseFees Fees to be paid by the buyer
   */
  function calculateServiceFees(uint256 _mintVoucherPrice, uint256 purchaseFees)
    internal
    pure
    returns (uint256)
  {
    return
      PercentageUtils.percentageCalculatorDiv(_mintVoucherPrice, purchaseFees);
  }

  /**
   * @dev Sets the % of the services fees
   * @param _newServiceFees Value in % of the services fees to set
   */
  function setServiceFees(uint256 _newServiceFees) private onlyOwner {
    require(
      _newServiceFees > 0 && _newServiceFees <= 5000,
      "Service fees cap is 5%"
    );
    _serviceFees = _newServiceFees;
  }

  /**
   * @dev Returns service fees
   */
  function serviceFees() public view returns (uint256) {
    return _serviceFees;
  }

  /**
   * @dev Unlists an NFT
   * @param signature Voucher signature
   */
  function unlistItem(bytes memory signature) public {
    isVoucherInvalid[signature] = false;
    emit UnlistedNFT(signature);
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
   * @param _amountToPurchase Amount of licenses to be purchased
   * @return uint256 Total order amount
   */
  function calculateAmountToPay(
    uint256 _tokenPrice,
    uint256 _fees,
    uint256 _amountToPurchase
  ) internal pure returns (uint256) {
    return
      _tokenPrice.mul(_amountToPurchase).add((_fees.mul(_amountToPurchase)));
  }

  /**
   * @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
   * @param voucher An MintVoucher to hash.
   */
  function _hash(MintVoucher calldata voucher) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "SVVoucher(uint256 price,string tokenUri,uint256 supply,uint256 maxSupply,bool isMaster,string currency,uint96 royaltyFeeMaster,uint96 royaltyFeeLicense,uint96 creatorOwnerSplit,uint256 validUntil)"
            ),
            voucher.price,
            keccak256(bytes(voucher.tokenUri)),
            voucher.supply,
            voucher.maxSupply,
            voucher.isMaster,
            keccak256(bytes(voucher.currency)),
            voucher.royaltyFeeMaster,
            voucher.royaltyFeeLicense,
            voucher.creatorOwnerSplit,
            voucher.validUntil
          )
        )
      );
  }

  /**
   * @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
   * @param voucher An SaleVoucher to hash.
   */
  function _hash(SaleVoucher calldata voucher) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "SVVoucher(address nftContractAddress,uint256 price,string tokenUri,uint256 supply,bool isMaster,string currency,uint256 validUntil)"
            ),
            voucher.nftContractAddress,
            voucher.price,
            keccak256(bytes(voucher.tokenUri)),
            voucher.supply,
            voucher.isMaster,
            keccak256(bytes(voucher.currency)),
            voucher.validUntil
          )
        )
      );
  }

  /**
   * @notice Returns the chain id of the current blockchain.
   * @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
   * the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
   */
  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * @notice Verifies the signature for a given Voucher, returning the address of the signer.
   * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
   * @param voucher An Voucher describing an unminted or minted NFT.
   */
  function _verify(MintVoucher calldata voucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function _verify(SaleVoucher calldata voucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  // Royalties
  function _setTokenRoyaltySplit(
    uint256 tokenId,
    uint96 royaltyFeeMaster,
    uint96 royaltyFeeLicense,
    uint96 creatorOwnerRoyaltySplit
  ) internal {
    setTokenRoyaltySplit(
      tokenId,
      royaltyFeeMaster,
      royaltyFeeLicense,
      creatorOwnerRoyaltySplit
    );
  }

  function _royaltySplitMaster(uint256 _tokenId, uint256 _salePrice)
    public
    view
    returns (uint256, uint256)
  {
    return royaltySplitMaster(_tokenId, _salePrice);
  }

  function _royaltySplitLicense(uint256 _tokenId, uint256 _salePrice)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return royaltySplitLicense(_tokenId, _salePrice);
  }
}
