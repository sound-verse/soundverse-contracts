//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable {
    using SafeMath for uint256;
    uint256 internal periodLength = 90 days;
    uint256[6] public cumulativeAmountToVest;
    bool public paused;
    IERC20 internal token;

    struct Recipient {
        uint256 withdrawnAmount;
        uint256 startDate;
        uint256 totalAmount;
    }
    uint256 public totalRecipients;
    mapping(address => Recipient) public recipients;

    event LogRecipientAdded(address recipient, uint256 totalAmount);
    event LogTokensClaimed(address recipient, uint256 amount);

   
    /**
     * @param _tokenAddress The address of the SVJ token
     * @param _cumulativeAmountToVest  The total amount of tokens that will be distributed to investors
     */
    constructor(
        address _tokenAddress,
        uint256[6] memory _cumulativeAmountToVest
    ) {
        require(
            _tokenAddress != address(0),
            "token address can not be zero address"
        );
        token = IERC20(_tokenAddress);
        cumulativeAmountToVest = _cumulativeAmountToVest;
        paused = false;
    }

    /**
     * @dev Function add recipient to the vesting contract
     * @param _recipientAddress The address of the recipient
     * @param _startDate  date vesting starts
     * @param _totalAmount total amounts investors will recieve at end of vesting
     */
    function addRecipient(
        address _recipientAddress,
        uint256 _startDate,
        uint256 _totalAmount
    ) public onlyOwner  {
        require(
            _recipientAddress != address(0),
            "Recepient Address can't be zero address"
        );
        require(_startDate != 0, "startDate can't be 0");
        

        recipients[_recipientAddress] = Recipient(
            0,
            _startDate,
            _totalAmount
        );
        emit LogRecipientAdded(_recipientAddress, _totalAmount);
    }

    /**
     * @dev Function add  multiple recipients to the vesting contract
     * @param _recipients Array of recipient addresses. The array length should be less than 230, otherwise it will overflow the gas limit
     * @param _startDate Array of start dates corresponding to recipients. same array limitation
     * @param _totalAmount Array of total amounts investors will recieve corresponding to recipients. same array limitation
     */
    function addMultipleRecipients(
        address[] memory _recipients,
        uint256[] memory _startDate,
        uint256[] memory _totalAmount
    ) public onlyOwner {
        require(
            _recipients.length < 230,
            "The recipients must be not more than 230"
        );
        require(
            _recipients.length == _totalAmount.length,
            "The two arryas are with different length"
        );

        for (uint256 i; i < _recipients.length; i++) {
           
            addRecipient(
                _recipients[i],
                _startDate[i],
                _totalAmount[i]
            );
            totalRecipients++;
        }
    }

    /**
     * @dev Function that withdraws all available tokens
     * when vesting is over
     */
    function claim() public {
        require(
            block.timestamp >= recipients[msg.sender].startDate,
            "The vesting hasn't started"
        );

        require(paused == false, "Vesting is paused");

        (uint256 owedAmount, uint256 calculatedAmount) = calculateAmount();
        recipients[msg.sender].withdrawnAmount = calculatedAmount;
        bool result = token.transfer(msg.sender, owedAmount);
        require(result, "The claim was not successful");
        emit LogTokensClaimed(msg.sender, owedAmount);
    }

    /**
     * @dev Function that returns the amount that the user can withdraw at the current period.
     * @return _owedAmount The amount that the user can withdraw at the current period.
     */
    function hasClaim() public view returns (uint256 _owedAmount) {
        require(paused == false, "Vesting is paused");
        if (block.timestamp < recipients[msg.sender].startDate) {
            return 0;
        }

        (uint256 owedAmount, uint256 _calc) = calculateAmount();
        return owedAmount;
    }

    /**
     * @dev Function that pauses all claims.
     */
    function vestingPause() public onlyOwner {
        if (paused == true) {
            paused = false;
        } else {
            paused = true;
        }
    }

    function calculateAmount()
        internal
        view
        returns (uint256 owedAmount, uint256 calculatedAmount)
    {
        uint256 period = block
            .timestamp
            .sub(recipients[msg.sender].startDate)
            .div(periodLength);

        if (period >= cumulativeAmountToVest.length) {
            period = cumulativeAmountToVest.length.sub(1);
        }
        calculatedAmount = percentageCalculatorDiv(period.mul(
            recipients[msg.sender].totalAmount
        ), 16667);
        owedAmount = calculatedAmount.sub(
            recipients[msg.sender].withdrawnAmount
        );
      

        return (owedAmount, calculatedAmount);
    }

    /**
     * @dev Recipient Getter. Can't check if key exisits explicitly
     * so if 0 is returned it does not exist anything greater it does
     * @param _recipient recipient addresses.
     */
    function getRecipient(address _recipient) public view returns (uint256) {
        return recipients[_recipient].totalAmount;
    }

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
