// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CommonUtils.sol";

// This contract uses the library to set and retrieve state variables
contract CommonUtilsModifier {
    address public erc721;
    address public erc1155;
    address public marketplace;

    constructor(
        address _erc721,
        address _erc1155,
        address _marketplace
    ) {
        erc721 = _erc721;
        erc1155 = _erc1155;
        marketplace = _marketplace;
    }

    function setState() external {
        CommonUtils.setStateVariables(erc721, erc1155, marketplace);
    }

    function getERC721State() external view returns (address erc721Address) {
        erc721Address = CommonUtils.erc721Address();
    }

    function getERC1155State() external view returns (address erc1155Address) {
        return erc1155Address = CommonUtils.erc1155Address();
    }

    function getMarketplaceState()
        external
        view
        returns (address marketplaceAddress)
    {
        marketplaceAddress = CommonUtils.marketplaceAddress();
    }

}
