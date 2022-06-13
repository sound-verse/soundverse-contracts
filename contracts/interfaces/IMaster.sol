// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMaster {
  function createMasterItem(
    address signer,
    string memory tokenURI,
    uint256 licensesAmount
  ) external returns (uint256);

  function transferMaster(
    address _signer,
    address _buyer,
    uint256 currentTokenId
  ) external;

  function tokenIdForURI(string memory _uri) external returns (uint256);

  function _getCreator(uint256 _tokenId) external view returns (address);

  function _getOwner(uint256 _tokenId) external view returns(address);
}
