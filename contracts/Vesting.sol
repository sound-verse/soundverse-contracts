//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PercentageCalculator.sol";

contract Vesting is Ownable {
    uint256 internal totalTimeVesting;
    uint256 public totalPercentages;
    uint256 public cumulativeAmountToVest;
    bool public paused;
    IERC20 internal token;

    struct Recipient {
        uint256 withdrawnAmount;
        uint256 withdrawPercentage;
        uint256 startDate;
        uint256 endDate;
    }
    uint256 public totalRecipients;
    mapping(address => Recipient) public recipients;

    event LogStartDateSet(address setter, uint256 startDate);
    event LogRecipientAdded(address recipient, uint256 withdrawPercentage);
    event LogTokensClaimed(address recipient, uint256 amount);

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

    /**
     * @param _tokenAddress The address of the SVJ token
     * @param _totalTimeVesting The total duration investors are locked for. 6 quarters minimum
     * @param _cumulativeAmountToVest  The total amount of tokens that will be distributed to investors
     */
    constructor(
        address _tokenAddress,
        uint256 _totalTimeVesting,
        uint256 _cumulativeAmountToVest
    ) {
        require(
            _tokenAddress != address(0),
            "token address can not be zero address"
        );
        token = IERC20(_tokenAddress);
        totalTimeVesting = _totalTimeVesting;
        cumulativeAmountToVest = _cumulativeAmountToVest;
        paused = false;
    }

    /**
     * @dev Function add recipient to the vesting contract
     * @param _recipientAddress The address of the recipient
     * @param _withdrawPercentage The percentage that the recipient should receive in each vesting period
     */
    function addRecipient(
        address _recipientAddress,
        uint256 _withdrawPercentage,
        uint256 _startDate,
        uint256 _endDate
    ) public onlyOwner onlyValidPercentages(_withdrawPercentage) {
        require(
            _recipientAddress != address(0),
            "Recepient Address can't be zero address"
        );
        totalPercentages = totalPercentages + _withdrawPercentage;
        require(totalPercentages <= 100000, "Total percentages exceeds 100%");
        totalRecipients++;

        recipients[_recipientAddress] = Recipient(
            0,
            _withdrawPercentage,
            _startDate,
            _endDate
        );
        emit LogRecipientAdded(_recipientAddress, _withdrawPercentage);
    }

    /**
     * @dev Function add  multiple recipients to the vesting contract
     * @param _recipients Array of recipient addresses. The arrya length should be less than 230, otherwise it will overflow the gas limit
     * @param _withdrawPercentages Corresponding percentages of the recipients
     */
    function addMultipleRecipients(
        address[] memory _recipients,
        uint256[] memory _withdrawPercentages,
        uint256[] memory _startDate,
        uint256[] memory _endDate
    ) public  onlyOwner {
        require(
            _recipients.length < 230,
            "The recipients must be not more than 230"
        );
        require(
            _recipients.length == _withdrawPercentages.length,
            "The two arryas are with different length"
        );

        for (uint256 i; i < _recipients.length; i++) {
            // No check on percentages is needed here as everything is 
            // done in the function addRecipient
            addRecipient(
                _recipients[i],
                _withdrawPercentages[i],
                _startDate[i],
                _endDate[i]
            );
            totalRecipients++;

        }
    }

    /**
     * @dev Function that withdraws all available tokens
     */
    function claim() public {
       

        require(
            recipients[msg.sender].startDate != 0,
            "The vesting hasn't started"
        );
        require(
            block.timestamp >= recipients[msg.sender].startDate,
            "The vesting hasn't started"
        );
        require(
            block.timestamp >= recipients[msg.sender].endDate,
            "The vesting period has not ended"
        );
        require(paused != true, "Vesting is paused");

        uint256 calculatedAmount = PercentageCalculator.div(
            cumulativeAmountToVest,
            recipients[msg.sender].withdrawPercentage
        );
        recipients[msg.sender].withdrawnAmount = calculatedAmount;
        bool result = token.transfer(msg.sender, calculatedAmount);
        require(result, "The claim was not successful");
        emit LogTokensClaimed(msg.sender, calculatedAmount);
    }

    /**
     * @dev Function that returns the amount that the user can withdraw at the current period.
     * @return _owedAmount The amount that the user can withdraw at the current period.
     */
    function hasClaim() public view returns (uint256 _owedAmount) {
        require(paused != true, "Vesting is paused");
        if (
            block.timestamp <= recipients[msg.sender].startDate &&
            block.timestamp >= recipients[msg.sender].endDate
        ) {
            return 0;
        }

        uint256 calculatedAmount = PercentageCalculator.div(
            cumulativeAmountToVest,
            recipients[msg.sender].withdrawPercentage
        );
        return calculatedAmount;
    }

    /**
     * @dev Function that pauses all claims.
     */
    function vestingPause() public onlyOwner {
        if (paused) {
            paused = false;
        }
        if (!paused) {
            paused = true;
        }
    }

    /**
     * @dev Recipient Getter. Can't check if key exisits explicitly
     * @param _recipient recipient addresses. 
     */
    function getRecipient(
        address _recipient
        
    ) public view returns (uint256) {
        return recipients[_recipient].withdrawPercentage;
    }
}
