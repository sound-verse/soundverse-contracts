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

    constructor(address _commonUtilsAddress)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
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
        uint256 tokenId;
        uint256 supply;
        bool isMaster;
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
     * @param _buyer The address of the account which will receive the NFT upon success.
     * @param _amountToPurchase scjajassk
     * @param _mintVoucher A signed NFTVoucher that describes the NFT to be redeemed.
     */
    function redeemItem(
        address _buyer,
        uint256 _amountToPurchase,
        MintVoucher calldata _mintVoucher
    ) public payable nonReentrant {
        address _signer = _verify(_mintVoucher);

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, _signer),
            "Signature invalid or unauthorized"
        );

        uint256 purchaseFees = serviceFees();

        // Calculate fees and requires to pay services fees on top
        uint256 calculatedServiceFees = PercentageUtils.percentageCalculatorDiv(
            _mintVoucher.price,
            purchaseFees
        );

        // Total amount to pay with service fees
        // _amountToPurchase gilt nur fuer Licenses!!!
        uint256 purchasePriceWithServiceFee = 0;
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
            msg.value >= purchasePriceWithServiceFee,
            "Insufficient funds to redeem"
        );

        //  TODO() require(_mintVoucher.sellCount == marketplaceSellCount);

        // true -> Mint
        // false -> Purchase
        uint256 tokenId = masterContract.tokenIdForURI(_mintVoucher.tokenUri);
        if (tokenId == 0) {
            tokenId = masterContract.createMasterItem(
                _signer,
                _mintVoucher.tokenUri,
                _mintVoucher.supply
            );
        }

        // Transfer NFTS
        uint256 licensesAmountFromSigner;
        if (_mintVoucher.isMaster == true) {
            //transfer money to seller
            payable(_signer).transfer(purchasePrice);

            // Transfer master and license(s) to buyer
            masterContract._transfer(_signer, _buyer, tokenId);
            licensesAmountFromSigner = licensesContract.balanceOf(
                _signer,
                tokenId
            );
            licensesContract._safeTransferFrom(
                _signer,
                _buyer,
                tokenId,
                licensesAmountFromSigner
            );
            _itemsSold.increment();
        } else {
            // Transfer license(s) to buyer
            licensesContract._safeTransferFrom(
                _signer,
                _buyer,
                tokenId,
                _amountToPurchase
            );
        }

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
     * @param _amountToPurchase Amount of licenses to be purchased
     * @return uint256 Total order amount
     */
    function calculateAmountToPay(
        uint256 _tokenPrice,
        uint256 _fees,
        uint256 _amountToPurchase
    ) internal pure returns (uint256) {
        return
            _tokenPrice.mul(_amountToPurchase).add(
                (_fees.mul(_amountToPurchase))
            );
    }

    /**
     * @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
     * @param voucher An MintVoucher to hash.
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
                            "MintVoucher(uint256 tokenId,uint256 minPrice,string uri)"
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
