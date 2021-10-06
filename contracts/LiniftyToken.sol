// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LiniftyToken is IERC20 {
    
    //Variables
    string public constant NAME = "Linifty Token";
    string public constant SYMBOL = "LINI";
    string public standard = "Linifty Token v1.0";
    uint8 public constant DECIMALS = 18;
    uint256 private totalSupply_;

    using SafeMath for uint256;

    //Mappings
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    address public contractOwner;

    //Constructor
    constructor(uint256 total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        contractOwner = msg.sender;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    //transfer
    function transfer(address to, uint256 numTokens) public override returns (bool sucess) {
        require(balances[msg.sender] >= numTokens, "Not enough balance");

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[to] = balances[to].add(numTokens);

        emit Transfer(msg.sender, to, numTokens);

        return true;
    }

    function allowance(address owner, address delegate) public view override returns (uint) {
        return allowed[owner][delegate];
    }

    function approve(address spender, uint256 numTokens) public override returns (bool sucess){
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 numTokens) public override returns (bool sucesss) {
        require(numTokens <= balances[from], "Not enough balance.");
        require(numTokens <= allowed[from][msg.sender], "Test error");

        balances[from] = balances[from].sub(numTokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
        balances[to] = balances[to].add(numTokens);

        emit Transfer(from, to, numTokens);

        return true;
    }
}
