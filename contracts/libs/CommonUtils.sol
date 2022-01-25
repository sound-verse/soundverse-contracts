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
        public
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
    ) external {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721Address = _erc721Address;
        ds.erc1155Address = _erc1155Address;
        ds.marketplaceAddress = _marketplaceAddress;
    }

    function erc721Address() external view returns (address) {
        return diamondStorage().erc721Address;
    }

    function erc1155Address() external view returns (address) {
        return diamondStorage().erc1155Address;
    }

    function marketplaceAddress() external view returns (address) {
        return diamondStorage().marketplaceAddress;
    }

    function toBytes(address a) external pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
}
