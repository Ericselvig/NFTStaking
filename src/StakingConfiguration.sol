// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IStakingConfiguration} from "./interfaces/IStakingConfiguration.sol";
import {INFTStaking} from "./interfaces/INFTStaking.sol";

/**
 * @title StakingConfiguration
 * @notice This contract is used to manage the staking configuration
 * @author Yash
 */
contract StakingConfiguration is IStakingConfiguration, Ownable2Step {
    address internal _rewardToken;
    address internal _stakingNFT;
    INFTStaking internal _nftStaking;
    uint256 internal _rewardPerBlock;
    uint256 internal _unbondingPeriod;
    uint256 internal _delayPeriod;

    constructor() Ownable(_msgSender()) {}

    ////////////////////////////
    /// Only Owner Functions ///
    ////////////////////////////

    /// @notice Set the reward token
    function setRewardToken(address rewardToken) external override onlyOwner {
        _rewardToken = rewardToken;
    }

    /// @notice Set the staking NFT
    function setStakingNFT(address stakingNFT) external override onlyOwner {
        _stakingNFT = stakingNFT;
    }

    /// @notice Set the reward per block
    function setRewardPerBlock(uint256 rewardPerBlock) external onlyOwner {
        if (_rewardPerBlock != 0) {
            _nftStaking.updateAllPositionRewards();
        }
        _rewardPerBlock = rewardPerBlock;
    }

    /// @notice Set the unbonding period
    function setUnbondingPeriod(uint256 unbondingPeriod) external onlyOwner {
        _unbondingPeriod = unbondingPeriod;
    }

    /// @notice Set the delay period
    function setDelayPeriod(uint256 delayPeriod) external onlyOwner {
        _delayPeriod = delayPeriod;
    }

    function setStakingContract(address nftStaking) external onlyOwner {
        _nftStaking = INFTStaking(nftStaking);
    }

    ///////////////////////////////
    /// External View Functions ///
    ///////////////////////////////

    /// @notice Get the reward token
    function getRewardToken() external view override returns (address) {
        return _rewardToken;
    }

    /// @notice Get the staking NFT
    function getStakingNFT() external view override returns (address) {
        return _stakingNFT;
    }

    /// @notice Get the reward per block
    function getRewardPerBlock() external view returns (uint256) {
        return _rewardPerBlock;
    }

    /// @notice Get the unbonding period
    function getUnbondingPeriod() external view returns (uint256) {
        return _unbondingPeriod;
    }

    /// @notice Get the delay period
    function getDelayPeriod() external view returns (uint256) {
        return _delayPeriod;
    }
}
