// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library CommonUtils {
    struct DiamondStorage {
        address erc721Address;
        address erc1155Address;
        address marketplaceAddress;
    }

    // return a struct storage pointer for accessing the state variables
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = keccak256("diamond.standard.diamond.storage");
        assembly {
            ds.slot := position
        }
    }

    // set state variables
    function setStateVariables(
        address _erc721Address,
        address _erc1155Address,
        address _marketplaceAddress
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721Address = _erc721Address;
        ds.erc1155Address = _erc1155Address;
        ds.marketplaceAddress = _marketplaceAddress;
    }

    function erc721Address() internal view returns (address) {
        return diamondStorage().erc721Address;
    }

    function erc1155Address() internal view returns (address) {
        return diamondStorage().erc1155Address;
    }

    function marketplaceAddress() internal view returns (address) {
        return diamondStorage().marketplaceAddress;
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
}

// This contract uses the library to set and retrieve state variables
contract LibraryModifier {
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
