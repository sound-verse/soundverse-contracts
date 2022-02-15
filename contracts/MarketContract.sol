// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "./SoundVerseERC721.sol";
import "./SoundVerseERC1155.sol";
import "./CommonUtils.sol";
import "./libs/PercentageUtils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MarketContract is
    AccessControlEnumerable,
    EIP712,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address payable internal admin;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    // Constants
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "SV-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    string public constant SV721 = "SoundVerseERC721";
    string public constant SV1155 = "SoundVerseERC1155";
    uint256 public _serviceFees;

    //Contracts
    ICommonUtils public commonUtils;
    ISoundVerseERC1155 public licensesContract;
    ISoundVerseERC721 public masterContract;

    constructor(
        // address payable _minter,
        address _commonUtilsAddress
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        // _setupRole(MINTER_ROLE, _minter);
        admin = payable(owner());

        commonUtils = ICommonUtils(_commonUtilsAddress);
        address sv1155 = commonUtils.getContractAddressFrom(SV1155);
        address sv721 = commonUtils.getContractAddressFrom(SV721);
        licensesContract = ISoundVerseERC1155(sv1155);
        masterContract = ISoundVerseERC721(sv721);
    }

    struct MintVoucher {
        address nftContractAddress;
        uint256 price;
        Counters.Counter sellCount;
        string tokenUri;
        uint256 licensesSupply;
        bytes signature;
    }

    struct ItemVoucher {
        uint256 tokenId;
        address nftContractAddress;
        uint256 price;
        Counters.Counter sellCount;
        bytes signature;
    }

    /**
     * @dev Event to be triggered after successful withdrawal
     */
    event Withdrawal(address _payee, uint256 _amount);

    function setServiceFees(uint256 _newServiceFees) private onlyOwner {
        require(
            _newServiceFees > 0 && _newServiceFees <= 5000,
            "Service fees cap is 5%"
        );
        _serviceFees = _newServiceFees;
    }

    function serviceFees() public view returns (uint256) {
        return _serviceFees;
    }

    /**
     * @dev Creates the sale of a marketplace item, transfers ownership of the item, as well as funds between parties
     * @param _mintVoucher Nft Voucher to be redeemed
     */
    function redeemAndMintItem(address _buyer, MintVoucher calldata _mintVoucher)
        public
        payable
        nonReentrant
    {
        address _signer = _verify(_mintVoucher);
        uint256 purchaseFees = serviceFees();

        // Calculate fees and requires to pay services fees on top
        uint256 calculatedServiceFees = PercentageUtils.percentageCalculatorDiv(
            _mintVoucher.price,
            purchaseFees
        );

        // Total amount to pay with service fees
        uint256 purchasePriceWithServiceFee = calculateAmountToPay(
            _mintVoucher.price,
            calculatedServiceFees
        );

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, _signer),
            "Signature invalid or unauthorized"
        );

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(
            msg.value >= purchasePriceWithServiceFee,
            "Insufficient funds to redeem"
        );

        //ERC-721 - Master
        masterContract.createMasterItem(
            _buyer,
            _signer,
            _mintVoucher.tokenUri,
            _mintVoucher.licensesSupply
        );

        withdrawFees(calculatedServiceFees);
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

    /**
     * @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
     * @param voucher An NFTVoucher to hash.
     */
    function _hash(MintVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"
                        ),
                        voucher.tokenUri,
                        voucher.price,
                        keccak256(bytes(voucher.tokenUri))
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
}
