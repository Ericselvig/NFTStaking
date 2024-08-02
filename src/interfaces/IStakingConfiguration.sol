// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingConfiguration {

    ///////////////
    /// SETTERS ///
    ///////////////
    function setRewardToken(address rewardToken) external;
    function setStakingNFT(address stakingNFT) external;
    function setRewardPerBlock(uint256 rewardPerBlock) external;
    function setDelayPeriod(uint256 delayPeriod) external;
    function setUnbondingPeriod(uint256 unbondingPeriod) external;
    function setStakingContract(address nftStaking) external;

    ///////////////
    /// GETTERS ///
    ///////////////
    function getRewardToken() external view returns (address);
    function getStakingNFT() external view returns (address); 
    function getRewardPerBlock() external view returns (uint256);
    function getDelayPeriod() external view returns (uint256);
    function getUnbondingPeriod() external view returns (uint256);
}