// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltyManager {

  function royaltySplitMaster(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (uint256, uint256);

  function royaltySplitLicense(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}
