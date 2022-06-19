// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./CommonUtils.sol";
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
  address internal licenseAddress;
  address internal masterAddress;

  // Events
  event UnlistedNFT(bytes signature);
  event RedeemedMintVoucher(bytes signature, address buyer, uint256 soldAmount);
  event RedeemedSaleVoucher(bytes signature, address buyer, uint256 soldAmount);

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

  function fillContractAddresses() internal {
    licenseAddress = commonUtils.getContractAddressFrom(LICENSE);
    masterAddress = commonUtils.getContractAddressFrom(MASTER);
  }

  /**
   * @dev Redeems a mint voucher. Lazy mints the item if it not exists and transfers the item to the buyer.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _mintVoucher A signed MintVoucher that describes the NFT to be redeemed.
   */
  function redeemMintVoucher(
    uint256 _amountToPurchase,
    MintVoucher calldata _mintVoucher
  ) public payable nonReentrant {
    require(
      _validateMintVoucher(_mintVoucher, _amountToPurchase) == true,
      "Signature is invalid."
    );

    if (licenseAddress == address(0) || masterAddress == address(0)) {
      fillContractAddresses();
    }

    address _signer = _getMintVoucherSigner(_mintVoucher);
    address _buyer = msg.sender;

    require(_signer != _buyer, "Seller is buyer.");

    uint256 tokenId = IMaster(masterAddress).getTokenIdForURI(
      _mintVoucher.tokenUri
    );

    if (tokenId == 0) {
      tokenId = mintItem(_signer, _mintVoucher);
    }

    payAndTransfer(
      tokenId,
      _buyer,
      _signer,
      _mintVoucher.price,
      _amountToPurchase,
      _mintVoucher.isMaster
    );

    voucherAmountSold[_mintVoucher.signature] = voucherAmountSold[
      _mintVoucher.signature
    ].add(_amountToPurchase);

    if (voucherAmountSold[_mintVoucher.signature] == _mintVoucher.supply) {
      isVoucherInvalid[_mintVoucher.signature] = false;
    }

    emit RedeemedMintVoucher(_mintVoucher.signature, _buyer, _amountToPurchase);
  }

  /**
   * @dev Redeems a sale voucher.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _saleVoucher A signed MintVoucher that describes the NFT to be redeemed.
   */
  function redeemSaleVoucher(
    uint256 _amountToPurchase,
    SaleVoucher calldata _saleVoucher
  ) public payable nonReentrant {
    require(
      _validateSaleVoucher(_saleVoucher, _amountToPurchase) == true,
      "Signature is invalid."
    );

    address _signer = _getSaleVoucherSigner(_saleVoucher);
    address _buyer = msg.sender;

    require(_signer != _buyer, "Seller is buyer.");

    uint256 tokenId = IMaster(masterAddress).getTokenIdForURI(
      _saleVoucher.tokenUri
    );

    payAndTransfer(
      tokenId,
      _buyer,
      _signer,
      _saleVoucher.price,
      _amountToPurchase,
      _saleVoucher.isMaster
    );

    voucherAmountSold[_saleVoucher.signature] = voucherAmountSold[
      _saleVoucher.signature
    ].add(_amountToPurchase);

    if (voucherAmountSold[_saleVoucher.signature] == _saleVoucher.supply) {
      isVoucherInvalid[_saleVoucher.signature] = false;
    }

    emit RedeemedSaleVoucher(_saleVoucher.signature, _buyer, _amountToPurchase);
  }

  /**
   * @notice Checks for the base requirements and returns true, if all conditions are met.
   * @param _mintVoucher An Voucher describing an unminted or minted NFT.
   * @param amountToPurchase Supply, buyer wants to purchase.
   */
  function _validateMintVoucher(
    MintVoucher calldata _mintVoucher,
    uint256 amountToPurchase
  ) internal view returns (bool) {
    require(
      isVoucherInvalid[_mintVoucher.signature] == false,
      "Voucher invalidated."
    );
    require(
      _mintVoucher.validUntil > block.timestamp,
      "Voucher timestamp exceeded."
    );

    require(
      _mintVoucher.supply >=
        amountToPurchase.add(voucherAmountSold[_mintVoucher.signature]),
      "Not enough supply."
    );

    return true;
  }

  /**
   * @notice Checks for the base requirements and returns true, if all conditions are met.
   * @param _saleVoucher An Voucher describing an unminted or minted NFT.
   * @param amountToPurchase Supply, buyer wants to purchase.
   */
  function _validateSaleVoucher(
    SaleVoucher calldata _saleVoucher,
    uint256 amountToPurchase
  ) internal view returns (bool) {
    require(
      isVoucherInvalid[_saleVoucher.signature] == false,
      "Voucher invalidated."
    );
    require(
      _saleVoucher.validUntil > block.timestamp,
      "Voucher timestamp exceeded."
    );
    require(
      _saleVoucher.supply >=
        amountToPurchase.add(voucherAmountSold[_saleVoucher.signature]),
      "Not enough supply."
    );

    return true;
  }

  /**
   * @dev Lazy mints the item
   * @param _signer The address of the account which will sell the NFT upon success.
   * @param _mintVoucher A signed MintVoucher that describes the NFT to be redeemed.
   */
  function mintItem(address _signer, MintVoucher calldata _mintVoucher)
    internal
    returns (uint256)
  {
    uint256 tokenId = IMaster(masterAddress).createMasterItem(
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

    return tokenId;
  }

  /**
   * @dev Monetary checklist for purchasing NFTs, will return purchase price
   * @param _price Price to be paid for NFT.
   * @param _amountToPurchase Amount of items to be purchased
   */
  function approvePurchase(uint256 _price, uint256 _amountToPurchase)
    internal
    returns (uint256, uint256)
  {
    uint256 valueTransmitted = msg.value;

    uint256 totalPriceWithServiceFees = calculateTotalPriceWithServiceFees(
      _price,
      _amountToPurchase
    );

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(
      valueTransmitted >= totalPriceWithServiceFees,
      "Insufficient funds to redeem."
    );

    uint256 caculatedServiceFees = totalPriceWithServiceFees.sub(
      _price.mul(_amountToPurchase)
    );

    return (totalPriceWithServiceFees, caculatedServiceFees);
  }

  /**
   * @dev Sets payment and transferring of the NFT
   * @param _tokenId TokenId of the NFT
   * @param _buyer The address of the buyer of the NFT
   * @param _signer The address of the account which will sell the NFT upon success
   * @param _price Price to be paid by the buyer
   * @param _amountToPurchase Amount of items to be purchased
   * @param _isMaster Is a Master nft or is a License
   */
  function payAndTransfer(
    uint256 _tokenId,
    address _buyer,
    address _signer,
    uint256 _price,
    uint256 _amountToPurchase,
    bool _isMaster
  ) internal {
    require(_tokenId != 0, "TokenId cannot be 0.");

    // Transfer NFTS
    uint256 licensesAmountFromSigner;
    uint256 royaltyAmountCreator;
    uint256 royaltyAmountOwner;
    uint256 restSalePrice;

    (uint256 totalPrice, uint256 caculatedServiceFees) = approvePurchase(
      _price,
      _amountToPurchase
    );

    if (_isMaster == true) {
      (royaltyAmountCreator, restSalePrice) = _royaltySplitMaster(
        _tokenId,
        totalPrice
      );

      address creator = IMaster(masterAddress)._getCreator(_tokenId);

      payable(creator).transfer(royaltyAmountCreator);

      //transfer money to seller
      payable(_signer).transfer(restSalePrice);

      //transfer service fees
      payable(admin).transfer(caculatedServiceFees);

      // Transfer master and license(s) to buyer
      IMaster(masterAddress).transferMaster(_signer, _buyer, _tokenId);
      licensesAmountFromSigner = ILicense(licenseAddress).licensesBalanceOf(
        _signer,
        _tokenId
      );
      ILicense(licenseAddress).transferLicenses(
        _signer,
        _buyer,
        _tokenId,
        licensesAmountFromSigner
      );
    } else {
      (
        royaltyAmountCreator,
        royaltyAmountOwner,
        restSalePrice
      ) = _royaltySplitLicense(_tokenId, totalPrice);

      address creator = ILicense(licenseAddress)._getCreator(_tokenId);
      address owner = IMaster(masterAddress)._getOwner(_tokenId);

      payable(creator).transfer(royaltyAmountCreator);
      payable(owner).transfer(royaltyAmountOwner);

      //transfer money to seller
      payable(_signer).transfer(restSalePrice);

      // Transfer license(s) to buyer
      ILicense(licenseAddress).transferLicenses(
        _signer,
        _buyer,
        _tokenId,
        _amountToPurchase
      );
    }
  }

  /**
   * @dev Calculates the services fees
   * @param _price Price to be paid by the buyer
   * @param _amount Amount the buyer wishes to purchase
   */
  function calculateTotalPriceWithServiceFees(uint256 _price, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    uint256 serviceFees = getServiceFees();
    uint256 priceWithServiceFees = _price.mul(serviceFees).div(100000);
    return _price.mul(_amount).add((priceWithServiceFees.mul(_amount)));
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
  function getServiceFees() public view returns (uint256) {
    return _serviceFees;
  }

  /**
   * @dev Unlists an NFT
   * @param signature Voucher signature
   */
  function unlistItem(bytes memory signature) public {
    isVoucherInvalid[signature] = true;
    emit UnlistedNFT(signature);
  }

  /**
   * @dev Service fees extraction and withdrawal
   * @param _calculatedFees Amount of fees to pay to marketplace
   */
  function withdrawFees(uint256 _calculatedFees) public payable {
    payable(admin).transfer(_calculatedFees);
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
   * @param _mintVoucher An MintVoucher to hash.
   */
  function _hashMintVoucher(MintVoucher calldata _mintVoucher)
    internal
    view
    returns (bytes32)
  {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "SVVoucher(uint256 price,string tokenUri,uint256 supply,uint256 maxSupply,bool isMaster,string currency,uint96 royaltyFeeMaster,uint96 royaltyFeeLicense,uint96 creatorOwnerSplit,uint256 validUntil)"
            ),
            _mintVoucher.price,
            keccak256(bytes(_mintVoucher.tokenUri)),
            _mintVoucher.supply,
            _mintVoucher.maxSupply,
            _mintVoucher.isMaster,
            keccak256(bytes(_mintVoucher.currency)),
            _mintVoucher.royaltyFeeMaster,
            _mintVoucher.royaltyFeeLicense,
            _mintVoucher.creatorOwnerSplit,
            _mintVoucher.validUntil
          )
        )
      );
  }

  /**
   * @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
   * @param _saleVoucher An SaleVoucher to hash.
   */
  function _hashSaleVoucher(SaleVoucher calldata _saleVoucher)
    internal
    view
    returns (bytes32)
  {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "SVVoucher(address nftContractAddress,uint256 price,string tokenUri,uint256 supply,bool isMaster,string currency,uint256 validUntil)"
            ),
            _saleVoucher.nftContractAddress,
            _saleVoucher.price,
            keccak256(bytes(_saleVoucher.tokenUri)),
            _saleVoucher.supply,
            _saleVoucher.isMaster,
            keccak256(bytes(_saleVoucher.currency)),
            _saleVoucher.validUntil
          )
        )
      );
  }

  /**
   * @notice Verifies the signature for a given Voucher, returning the address of the signer.
   * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
   * @param _mintVoucher An Voucher describing an unminted or minted NFT.
   */
  function _getMintVoucherSigner(MintVoucher calldata _mintVoucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hashMintVoucher(_mintVoucher);
    return ECDSA.recover(digest, _mintVoucher.signature);
  }

  /**
   * @notice Verifies the signature for a given Voucher, returning the address of the signer.
   * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
   * @param _saleVoucher An Voucher describing an unminted or minted NFT.
   */
  function _getSaleVoucherSigner(SaleVoucher calldata _saleVoucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hashSaleVoucher(_saleVoucher);
    return ECDSA.recover(digest, _saleVoucher.signature);
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
