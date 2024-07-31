// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {INFTStaking} from "./interfaces/INFTStaking.sol";
import {IStakingConfiguration} from "./interfaces/IStakingConfiguration.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title NFTStaking
 * @notice This contract is used to stake NFTs and earn rewards
 * @author Yash
 */
contract NFTStaking is
    INFTStaking,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable,
    IERC721Receiver
{
    IStakingConfiguration internal _config;
    mapping(uint256 tokenId => StakingPosition) internal _positions;

    /**
     * @dev modifier to check if the caller is the owner of the position
     */
    modifier onlyPositionOwner(uint256 _tokenId) {
        address positionOwner = _positions[_tokenId].owner;
        if (positionOwner != _msgSender()) {
            revert NFTStaking__NotPositionOwner();
        }
        _;
    }

    function initialize(address config) external initializer {
        __Ownable_init(_msgSender());
        __Pausable_init();
        _config = IStakingConfiguration(config);
    }

    /**
     * @inheritdoc INFTStaking
     */
    function stake(
        uint256[] calldata _tokenIds
    ) external override whenNotPaused {
        for (uint i; i < _tokenIds.length; ++i) {
            _stake(_tokenIds[i]);
        }
        emit Staked(_msgSender(), _tokenIds);
    }

    /**
     * @inheritdoc INFTStaking
     */
    function unstake(
        uint256[] calldata _tokenIds
    ) external override whenNotPaused {
        for (uint i; i < _tokenIds.length; ++i) {
            _unstake(_tokenIds[i]);
        }
        emit Unstaked(_msgSender(), _tokenIds);
    }

    /**
     * @inheritdoc INFTStaking
     */
    function withdraw(
        uint256 _tokenId
    ) external override whenNotPaused onlyPositionOwner(_tokenId) {
        StakingPosition memory position = _positions[_tokenId];
        if (
            position.unstakeTimestamp + _config.getUnbondingPeriod() >
            block.timestamp
        ) {
            revert NFTStaking__UnbondingPeriod();
        }
        delete _positions[_tokenId];
        IERC721(_config.getStakingNFT()).safeTransferFrom(
            address(this),
            _msgSender(),
            _tokenId
        );
        emit Withdrawn(_msgSender(), _tokenId);
    }

    /**
     * @inheritdoc INFTStaking
     */
    function claimRewards(
        uint256 _tokenId
    ) external override whenNotPaused onlyPositionOwner(_tokenId) {
        StakingPosition memory position = _positions[_tokenId];
        if (
            position.lastClaimedAt + _config.getDelayPeriod() > block.timestamp
        ) {
            revert NFTStaking__DelayPeriod();
        }
        uint256 pending = getPendingRewards(_tokenId);

        position.lastClaimedAt = block.timestamp;
        _positions[_tokenId].claimedRewards += pending;

        IERC20(_config.getRewardToken()).transfer(_msgSender(), pending);

        emit RewardsClaimed(msg.sender, pending);
    }

    /**
     * @dev internal function to stake an NFT
     */
    function _stake(uint256 _tokenId) internal {
        IERC721(_config.getStakingNFT()).safeTransferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );
        _positions[_tokenId] = StakingPosition({
            owner: _msgSender(),
            stakedAt: block.number,
            lastClaimedAt: block.timestamp,
            claimedRewards: 0,
            unstakedAt: 0,
            unstakeTimestamp: 0
        });
    }

    /**
     * @dev internal function to unstake an NFT
     */
    function _unstake(uint256 _tokenId) internal onlyPositionOwner(_tokenId) {
        StakingPosition memory position = _positions[_tokenId];
        position.unstakedAt = block.number;
        position.unstakeTimestamp = block.timestamp;
        _positions[_tokenId] = position;
    }

    /**
     * @inheritdoc INFTStaking
     */
    function getPendingRewards(
        uint256 _tokenId
    ) public view override returns (uint256) {
        StakingPosition memory position = _positions[_tokenId];
        uint256 finalBlock = position.unstakedAt == 0
            ? block.number
            : position.unstakedAt;
        uint256 pending = (finalBlock - position.stakedAt) *
            _config.getRewardPerBlock() -
            position.claimedRewards;
        return pending;
    }

    /**
     * @inheritdoc INFTStaking
     */
    function getStakingPosition(
        uint256 _tokenId
    ) external view override returns (StakingPosition memory) {
        return _positions[_tokenId];
    }

    /// @dev function to pause/unpause
    function pause(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @inheritdoc UUPSUpgradeable
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
