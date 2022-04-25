// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILicense {
    function mintLicenses(
        address signer,
        string memory mintURI,
        uint256 amount,
        bytes memory erc721Reference,
        uint96 _royaltyFeeInBips
    ) external;

    function transferLicenses(
        address _signer,
        address _buyer,
        uint256 _currentLicenseBundleId,
        uint256 _amountToPurchase
    ) external;

    function licensesBalanceOf(address account, uint256 id) external returns(uint256);

}