// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICommonUtils {
    function getContractAddressFrom(string memory _contractName)
        external
        view
        returns (address);

    function setContractAddressFor(
        string memory _contractName,
        address _contractAddress
    ) external;

    function toBytes(uint256 a) external pure returns (bytes memory);

    function compareStrings(string memory a, string memory b)
        external
        pure
        returns (bool);
}

contract CommonUtils {
    mapping(string => address) public addressBook;

    constructor() {}

    function getContractAddressFrom(string memory _contractName)
        public
        view
        returns (address)
    {
        return addressBook[_contractName];
    }

    function setContractAddressFor(
        string memory _contractName,
        address _contractAddress
    ) public {
        addressBook[_contractName] = _contractAddress;
    }

    function toBytes(uint256 a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
