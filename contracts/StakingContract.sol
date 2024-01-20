// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingContract is ReentrancyGuard {

    IERC20 public ATokenAddress;
    IERC20 public BTokenAddress;

    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public startTime;
    mapping(address => bool) public isStaking;
    uint256 public constant APY = 10;
    uint256 public constant DIVIDER = 10000;  

    event Staking(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaking(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _ATokenAddress, address _BTokenAddress) {
        ATokenAddress = IERC20(_ATokenAddress);
        BTokenAddress = IERC20(_BTokenAddress);
    }

    modifier isUserStaking(address user) {
        require(isStaking[user] == true, "You are not staking");
        _;
    }

    modifier ATokenAllowance(address user, uint256 amount) {
        require(ATokenAddress.allowance(user, address(this)) >= amount, "Please approve AToken first");
        _;
    }

    modifier BTokenAllowance(address user, uint256 amount) {
        require(BTokenAddress.allowance(user, address(this)) >= amount, "Please approve AToken first");
        _;
    }

    function stake(uint256 amount) public nonReentrant ATokenAllowance(msg.sender, amount) {
        require(amount > 0, "Amount cannot be 0");
        
        stakingBalance[msg.sender] += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;

        bool sent = ATokenAddress.transferFrom(msg.sender, address(this), amount);
        require(sent == true, "Failed to send AToken");
        sent = BTokenAddress.transfer(msg.sender, amount);
        require(sent == true, "Failed to send BToken");

        emit Staking(msg.sender, amount, block.timestamp);
    }

    function unstake(uint256 amount) public nonReentrant isUserStaking(msg.sender) BTokenAllowance(msg.sender, amount) {
        uint256 balance = stakingBalance[msg.sender];
        require(balance >= amount, "Cannot withdraw more than staked");

        (uint256 yield, uint256 timestamp) = calculateYield(msg.sender, amount);
        uint256 withdrawAmount = amount + yield;
        require(ATokenAddress.balanceOf(address(this)) >= withdrawAmount, "Not enough AToken in contract");

        stakingBalance[msg.sender] = balance - amount;
        startTime[msg.sender] = timestamp;

        bool sent = BTokenAddress.transferFrom(msg.sender, address(this), amount);
        require(sent == true, "Failed to send BToken");
        sent = ATokenAddress.transfer(msg.sender, withdrawAmount);
        require(sent == true, "Failed to send AToken");
        
        emit Unstaking(msg.sender, withdrawAmount, timestamp);
    }

    function calculateYield(address user, uint256 amount) public view returns (uint256, uint256) {
        uint256 timestamp = block.timestamp;
        uint256 stakingTimeInSeconds = block.timestamp - startTime[user];
        uint256 stakingTimeInMonths = stakingTimeInSeconds * DIVIDER / 30 days;
        uint256 yield = (amount * DIVIDER * APY / 100) * stakingTimeInMonths / 12;
        return (yield / DIVIDER / DIVIDER, timestamp);
    }
}
