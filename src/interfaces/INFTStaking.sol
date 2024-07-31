// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTStaking
 * @notice Interface for NFTStaking contract
 * @author Yash
 */
interface INFTStaking {
    //////////////
    /// Events ///
    //////////////
    event Staked(address indexed user, uint256[] tokenIds);
    event Unstaked(address indexed user, uint256[] tokenIds);
    event Withdrawn(address indexed user, uint256 tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);

    //////////////
    /// Errors ///
    //////////////
    error NFTStaking__NotPositionOwner();
    error NFTStaking__DelayPeriod();
    error NFTStaking__UnbondingPeriod();

    /// staking position struct
    struct StakingPosition {
        address owner; // owner of the position
        uint256 stakedAt; // block number on which the nft was staked at
        uint256 lastClaimedAt; // the timestamp where rewards were last claimed
        uint256 claimedRewards; // total claimed rewards
        uint256 unstakedAt; // block number on which the nft was unstaked at
        uint256 unstakeTimestamp; // timestamp at which the nft was unstaked
    }

    /**
     * @notice Stake multiple NFTs
     * @param _tokenIds Array of token ids to stake
     */
    function stake(uint256[] calldata _tokenIds) external;

    /**
     * @notice Unstake one or more NFTs
     * @param _tokenIds Array of token ids to unstake
     */
    function unstake(uint256[] calldata _tokenIds) external;

    /**
     * @notice Withdraw NFT from the contract
     * @param _tokenId Token id to withdraw
     * @dev can only withdraw after unbonding period
     * @dev resets the position
     */
    function withdraw(uint256 _tokenId) external;

    /**
     * @notice Claim rewards for a token id
     * @param _tokenId Token id to claim rewards for
     * @dev can only claim after delay period
     */
    function claimRewards(uint256 _tokenId) external;

    /**
     * @notice Get pending rewards for a token id
     * @param _tokenId Token id to get pending rewards for
     * @dev calculates pending rewards based on the reward per block
     * @dev only calculates rewards upto the unstakedAt block, if nft is unstaked
     * @return Pending rewards
     */
    function getPendingRewards(
        uint256 _tokenId
    ) external view returns (uint256);


    /**
     * @notice Get staking position for a token id
     * @param _tokenId Token id to get staking position for
     * @return Staking position
     */
    function getStakingPosition(
        uint256 _tokenId
    ) external view returns (StakingPosition memory);
}
