// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IRoyaltyManager.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RoyaltyManager is IRoyaltyManager {
  using SafeMath for uint256;

  struct RoyaltySplit {
    uint96 royaltyFeeMaster;
    uint96 royaltyFeeLicense;
    uint96 creatorOwnerRoyaltySplit;
  }

  mapping(uint256 => RoyaltySplit) private _tokenRoyaltySplit;

  function _splitFeeDenominator() internal pure virtual returns (uint96) {
    return 10000;
  }

  function royaltySplitMaster(uint256 _tokenId, uint256 _salePrice)
    public
    view
    virtual
    override
    returns (uint256, uint256)
  {
    RoyaltySplit memory royalty = _tokenRoyaltySplit[_tokenId];

    uint256 royaltyAmountMaster = (_salePrice * royalty.royaltyFeeMaster) /
      _splitFeeDenominator();

    uint256 restSalePrice = _salePrice.sub(royaltyAmountMaster);

    return (royaltyAmountMaster, restSalePrice);
  }

  function royaltySplitLicense(uint256 _tokenId, uint256 _salePrice)
    public
    view
    virtual
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    RoyaltySplit memory royalty = _tokenRoyaltySplit[_tokenId];

    uint256 royaltyAmount = (_salePrice * royalty.royaltyFeeLicense) /
      _splitFeeDenominator();

    uint256 royaltyAmountCreator = (royaltyAmount *
      royalty.creatorOwnerRoyaltySplit) / _splitFeeDenominator();

    uint256 royaltyAmountOwner = royaltyAmount.sub(royaltyAmountCreator);

    uint256 restSalePrice = _salePrice.sub(royaltyAmount);

    return (royaltyAmountCreator, royaltyAmountOwner, restSalePrice);
  }

  function setTokenRoyaltySplit(
    uint256 tokenId,
    uint96 royaltyFeeMaster,
    uint96 royaltyFeeLicense,
    uint96 creatorOwnerRoyaltySplit
  ) external {
    require(
      royaltyFeeMaster <= _splitFeeDenominator(),
      "RoyaltyManager: royalties cannot be more then 100%"
    );
    require(
      royaltyFeeLicense <= _splitFeeDenominator(),
      "RoyaltyManager: royalties cannot be more then 100%"
    );

    require(
      creatorOwnerRoyaltySplit <= _splitFeeDenominator(),
      "RoyaltyManager: royalties cannot be more then 100%"
    );

    _tokenRoyaltySplit[tokenId] = RoyaltySplit(
      royaltyFeeMaster,
      royaltyFeeLicense,
      creatorOwnerRoyaltySplit
    );
  }

}
