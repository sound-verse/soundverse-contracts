// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./CommonUtils.sol";
import "./libs/PercentageUtils.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/ILicense.sol";
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
  ReentrancyGuard
{
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  address payable internal admin;
  Counters.Counter private itemsSold;
  uint256 public _serviceFees;
  uint256 public sellCount;

  // Constants
  string internal constant SIGNING_DOMAIN = "SVVoucher";
  string internal constant SIGNATURE_VERSION = "1";
  string internal constant MASTER = "Master";
  string internal constant LICENSE = "License";

  // Mappings
  mapping(address => mapping(address => mapping(string => uint256)))
    public sellCounts;

  //Contracts
  ICommonUtils public commonUtils;
  ILicense public licensesContract;
  IMaster public masterContract;

  // Events
  event Withdrawal(address _payee, uint256 _amount);
  event UnlistedNFT(string tokenUri, address contractAddress, address caller);

  // Structs
  struct NFTVoucher {
    address nftContractAddress;
    uint256 price;
    uint256 sellCount;
    string tokenUri;
    uint256 tokenId;
    uint256 supply;
    uint256 maxSupply;
    bool isMaster;
    bytes signature;
    string currency;
    uint96 royaltyFeeInBeeps;
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
    address licenseAddress = commonUtils.getContractAddressFrom(LICENSE);
    address masterAddress = commonUtils.getContractAddressFrom(MASTER);
    licensesContract = ILicense(licenseAddress);
    masterContract = IMaster(masterAddress);
  }

  /**
   * @dev Creates the sale of a marketplace item, transfers ownership of the item, as well as funds between parties
   * @param _buyer The address of the account which will receive the NFT upon success.
   * @param _seller The address of the account which will sell the NFT upon success.
   * @param _amountToPurchase Amount of items to be purchased
   * @param _mintVoucher A signed NFTVoucher that describes the NFT to be redeemed.
   */
  function redeemItem(
    address _buyer,
    address _seller,
    uint256 _amountToPurchase,
    NFTVoucher calldata _mintVoucher
  ) public payable nonReentrant {
    console.log("REDEEMITEM STARTING....");
    uint256 totalPurchase = msg.value;
    require(totalPurchase > 0, "No amount being transferred");
    address _signer = _verify(_mintVoucher);

    // make sure that the signer of the Voucher is the seller
    require(_seller == _signer, "Signature invalid");

    uint256 purchaseFees = serviceFees();

    // Calculate fees and requires to pay services fees on top
    uint256 calculatedServiceFees = PercentageUtils.percentageCalculatorDiv(
      _mintVoucher.price,
      purchaseFees
    );

    // Total amount to pay with service fees
    uint256 purchasePriceWithServiceFee;
    if (_mintVoucher.isMaster == true) {
      purchasePriceWithServiceFee = calculateAmountToPay(
        _mintVoucher.price,
        calculatedServiceFees,
        1
      );
    } else {
      purchasePriceWithServiceFee = calculateAmountToPay(
        _mintVoucher.price,
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

    require(
      sellCounts[_signer][_mintVoucher.nftContractAddress][
        _mintVoucher.tokenUri
      ] == _mintVoucher.sellCount,
      "Signature not valid"
    );

    initializeContracts();

    // true -> Mint
    // false -> Purchase
    uint256 tokenId = masterContract.tokenIdForURI(_mintVoucher.tokenUri);
    if (tokenId == 0) {
      console.log("CREATE MASTER ITEM about to be called....");
      tokenId = masterContract.createMasterItem(
        _signer,
        _mintVoucher.tokenUri,
        _mintVoucher.maxSupply,
        _mintVoucher.royaltyFeeInBeeps
      );
    }

    require(tokenId != 0, "NFT could not be minted");
    // Transfer NFTS
    uint256 licensesAmountFromSigner;
    if (_mintVoucher.isMaster == true) {
      //transfer money to seller
      payable(_signer).transfer(purchasePrice);

      // Transfer master and license(s) to buyer
      masterContract.transferMaster(_signer, _buyer, tokenId);
      licensesAmountFromSigner = licensesContract.licensesBalanceOf(
        _signer,
        tokenId
      );
      licensesContract.transferLicenses(
        _signer,
        _buyer,
        tokenId,
        licensesAmountFromSigner
      );
      itemsSold.increment();
    } else {
      // Transfer license(s) to buyer
      licensesContract.transferLicenses(
        _signer,
        _buyer,
        tokenId,
        _amountToPurchase
      );
    }
    incrementSellCount(
      _signer,
      _mintVoucher.nftContractAddress,
      _mintVoucher.tokenUri
    );
    withdrawFees(calculatedServiceFees);
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
   * @dev Gets the sell count if it exists, otherwise returns 0
   * @param _ownerAddress Address of the NFT owner
   * @param _tokenUri TokenUri of the NFT
   */
  function getSellCount(
    address _ownerAddress,
    address _nftContractAddress,
    string memory _tokenUri
  ) public view returns (uint256) {
    if (sellCounts[_ownerAddress][_nftContractAddress][_tokenUri] == 0) {
      return 0;
    }
    return sellCounts[_ownerAddress][_nftContractAddress][_tokenUri];
  }

  /**
   * @dev Increments the sell count
   * @param _nftContractAddress Address of the NFT contract
   * @param _tokenUri TokenUri of the NFT
   */
  function incrementSellCount(
    address _sender,
    address _nftContractAddress,
    string memory _tokenUri
  ) private {
    sellCounts[_sender][_nftContractAddress][_tokenUri] += 1;
  }

  /**
   * @dev Increments the sell count
   * @param _nftContractAddress Address of the NFT contract
   * @param _tokenUri TokenUri of the NFT
   */
  function unlistItem(address _nftContractAddress, string memory _tokenUri)
    public
  {
    address _sender = _msgSender();
    incrementSellCount(_sender, _nftContractAddress, _tokenUri);
    emit UnlistedNFT(_tokenUri, _nftContractAddress, _sender);
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
   * @param voucher An NFTVoucher to hash.
   */
  function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "SVVoucher(address nftContractAddress,uint256 price,uint256 sellCount,string tokenUri,uint256 tokenId,uint256 supply,uint256 maxSupply,bool isMaster,string currency,uint96 royaltyFeeInBeeps)"
            ),
            voucher.nftContractAddress,
            voucher.price,
            voucher.sellCount,
            keccak256(bytes(voucher.tokenUri)),
            voucher.tokenId,
            voucher.supply,
            voucher.maxSupply,
            voucher.isMaster,
            keccak256(bytes(voucher.currency)),
            voucher.royaltyFeeInBeeps
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
  function _verify(NFTVoucher calldata voucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hash(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }
}
