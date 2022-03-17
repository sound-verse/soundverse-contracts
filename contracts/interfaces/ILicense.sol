// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILicense {
    function mintLicenses(
        address signer,
        string memory mintURI,
        uint256 amount,
        bytes memory erc721Reference
    ) external;

    function _safeTransferFrom(
        address _signer,
        address _buyer,
        uint256 _currentLicenseBundleId,
        uint256 _amountToPurchase
    ) external;

    function balanceOf(address account, uint256 id) external returns(uint256);

}