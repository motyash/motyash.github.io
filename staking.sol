// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    address public owner;
    uint public stakingPeriod;
    uint public totalRewards;
    mapping(address => uint) public userBalances;
    mapping(address => uint) public stakedBalances;
    mapping(address => uint) public stakingStartTimes;
    address[] public stakers;
    IERC20 public token;

    constructor(uint _stakingPeriod, uint _totalRewards, address _tokenAddress) {
        owner = msg.sender;
        stakingPeriod = _stakingPeriod;
        totalRewards = _totalRewards;
        token = IERC20(_tokenAddress);
    }

    function stake(uint _amount) public {
        require(_amount > 0, "Staked amount must be greater than 0");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        userBalances[msg.sender] -= _amount;
        require(token.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed");
        stakedBalances[msg.sender] += _amount;
        stakingStartTimes[msg.sender] = block.timestamp;

        if (stakingStartTimes[msg.sender] != 0) {
            stakers.push(msg.sender);
        }
    }

    function calculateRewards(address _user) public view returns (uint) {
        uint stakedAmount = stakedBalances[_user];
        uint startTime = stakingStartTimes[_user];

        if (startTime == 0) {
            return 0;
        }

        uint timeStaked = block.timestamp - startTime;

        if (timeStaked >= stakingPeriod) {
            return totalRewards;
        }

        return (stakedAmount * timeStaked * totalRewards) / (stakingPeriod * 1 days);
    }

    function distributeRewards() public {
        require(msg.sender == owner, "Only the owner can distribute rewards");

        for (uint i = 0; i < stakers.length; i++) {
            address user = stakers[i];
            uint rewards = calculateRewards(user);
            userBalances[user] += rewards;
            stakingStartTimes[user] = 0;
        }
    }

    function withdraw() public {
        uint stakedAmount = stakedBalances[msg.sender];
        uint rewards = calculateRewards(msg.sender);

        require(stakedAmount > 0, "Nothing to withdraw");
        require(token.transfer(msg.sender, stakedAmount + rewards), "Withdraw transfer failed");

        userBalances[msg.sender] += stakedAmount + rewards;
        stakedBalances[msg.sender] = 0;
        stakingStartTimes[msg.sender] = 0;
    }

    function getStakedBalance(address _user) public view returns (uint) {
        return stakedBalances[_user];
    }

    function getRewardsBalance(address _user) public view returns (uint) {
        return userBalances[_user];
    }
}
