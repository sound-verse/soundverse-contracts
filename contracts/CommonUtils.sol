// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CommonUtils {
    struct AddressData {
     address contractAddress;
     bool exists;
   }

    mapping(string => AddressData) public addressBook;

    constructor() {}

    function getContractAddressFrom(string memory _contractName)
        public
        view
        returns (address)
    {
        return addressBook[_contractName].contractAddress;
    }

    function setContractAddressFor(
        string memory _contractName,
        address _contractAddress
    ) public {
        require(addressBook[_contractName].exists == false, "The address for the contract exists.");
        addressBook[_contractName].contractAddress = _contractAddress;
        addressBook[_contractName].exists = true;
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }
}
