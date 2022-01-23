//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PercentageUtils {
    using SafeMath for uint256;

    function percentageCalculatorDiv(uint256 _amount, uint256 _percentage)
        public
        pure
        returns (uint256)
    {
        /*
	Note: Percentages will be provided in thousands to represent 3 digits after the decimal point.
	The division is made by 100000 
	*/

        return _amount.mul(_percentage).div(100000);
    }
}

abstract contract ValidPercentages {
        /*
     * Note: Percentages will be provided in thousands to represent 3 digits after the decimal point.
     * Ex. 10% = 10000
     */
    modifier onlyValidPercentages(uint256 _percentage) {
        require(
            _percentage <= 100000,
            "Provided percentage should be less than 100%"
        );
        require(
            _percentage > 0,
            "Provided percentage should be greater than 0"
        );
        _;
    }
}