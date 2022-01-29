// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
}
