// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StakingConfiguration} from "../src/StakingConfiguration.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC721Mock} from "./mocks/ERC721Mock.sol";
import {NFTStakingMock} from "./mocks/NFTStakingMock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTStakingTest is Test {
    ERC1967Proxy proxy;
    ERC20Mock rewardToken;
    ERC721Mock stakingNFT;
    NFTStaking staking;
    StakingConfiguration config;
    address alice;
    address bob;

    function setUp() public {
        rewardToken = new ERC20Mock();
        stakingNFT = new ERC721Mock();

        config = new StakingConfiguration();
        config.setRewardToken(address(rewardToken));
        config.setDelayPeriod(100);
        config.setUnbondingPeriod(100);
        config.setStakingNFT(address(stakingNFT));
        config.setRewardPerBlock(1e18);

        staking = new NFTStaking();
        proxy = new ERC1967Proxy(
            address(staking),
            abi.encodeWithSelector(staking.initialize.selector, address(config))
        );

        config.setStakingContract(address(proxy));

        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    modifier mintAndStake(address user, uint256 tokenId) {
        _mintAndStake(user, tokenId);
        _;
    }

    function _mintAndStake(address user, uint256 tokenId) internal {
        stakingNFT.mint(user, tokenId);
        vm.startPrank(user);
        stakingNFT.approve(address(proxy), tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.stake.selector, tokenIds)
        );
        require(ok);
        vm.stopPrank();
    }

    function testOwnerCanUpgradeContract() external {
        NFTStakingMock stakingMock = new NFTStakingMock();
        NFTStaking _proxy = NFTStaking(address(proxy));
        _proxy.upgradeToAndCall(address(stakingMock), "");
        (bool ok, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(stakingMock.getVersion.selector, "")
        );
        require(ok);
        uint256 version = abi.decode(data, (uint256));
        assertEq(version, 2);
    }

    function testStakingContractCannotBeInitializedAgain() external {
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.initialize.selector, address(config))
        );
        vm.expectRevert();
        require(ok);
    }

    function testUserCanStakeNFT() external mintAndStake(alice, 1) {
        assertEq(stakingNFT.ownerOf(1), address(proxy));
        (bool ok, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(staking.getStakingPosition.selector, 1)
        );
        require(ok);
        (address owner, uint256 stakedAt, , , , ) = abi.decode(
            data,
            (address, uint256, uint256, uint256, uint256, uint256)
        );
        assertEq(owner, alice);
        assertEq(stakedAt, block.number);
    }

    function testUserCanStakeMultipleNFTs() external {
        uint256[] memory tokenIds = new uint256[](10);

        for (uint i; i < 10; i++) {
            stakingNFT.mint(alice, i);
            vm.prank(alice);
            stakingNFT.approve(address(proxy), i);
            tokenIds[i] = i;
        }

        vm.prank(alice);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.stake.selector, tokenIds)
        );
        require(ok);

        for (uint i; i < 10; i++) {
            assertEq(stakingNFT.ownerOf(i), address(proxy));
            (bool success, bytes memory data) = address(proxy).call(
                abi.encodeWithSelector(staking.getStakingPosition.selector, i)
            );
            require(success);
            (address owner, uint256 stakedAt, , , , ) = abi.decode(
                data,
                (address, uint256, uint256, uint256, uint256, uint256)
            );
            assertEq(owner, alice);
            assertEq(stakedAt, block.number);
        }
    }

    function testUserCannotStakeOrUnstakeIfPaused()
        external
        mintAndStake(bob, 1)
    {
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSignature("pause(bool)", true)
        );
        require(ok);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(bob);
        vm.expectRevert();
        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );
        require(ok);

        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.stake.selector, tokenIds)
        );
        vm.expectRevert();
        require(ok);
        vm.stopPrank();

        (ok, ) = address(proxy).call(
            abi.encodeWithSignature("pause(bool)", false)
        );
        require(ok);

        vm.prank(bob);
        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );
        require(ok);
    }

    function testUserCanUnstakeNFT() external mintAndStake(alice, 3) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 3;
        vm.roll(block.number + 10);
        vm.warp(block.timestamp + 100);
        vm.prank(alice);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );
        assertEq(stakingNFT.ownerOf(3), address(proxy)); // user has not withdrawn yet
        (bool success, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(staking.getStakingPosition.selector, 3)
        );
        (
            address owner,
            ,
            ,
            ,
            ,
            uint256 unstakedAt,
            uint256 unstakeTimestamp
        ) = abi.decode(
                data,
                (address, uint256, uint256, uint256, uint256, uint256, uint256)
            );
        assertEq(owner, address(alice));
        assertEq(unstakedAt, block.number);
        assertEq(unstakeTimestamp, block.timestamp);
    }

    function testUserCannotUnstakeIfNotOwner() external mintAndStake(bob, 1) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.expectRevert();
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );
    }

    function testUserCanWithdraw() external mintAndStake(bob, 1) {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.startPrank(bob);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );

        vm.warp(block.timestamp + config.getUnbondingPeriod());

        (bool success, ) = address(proxy).call(
            abi.encodeWithSelector(staking.withdraw.selector, tokenIds[0])
        );

        assertEq(stakingNFT.ownerOf(1), address(bob));
    }

    function testUserCannotWithdrawIfNotUnbonded()
        external
        mintAndStake(bob, 1)
    {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.startPrank(bob);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );

        vm.warp(block.timestamp + config.getUnbondingPeriod() - 1);

        vm.expectRevert();
        (bool success, ) = address(proxy).call(
            abi.encodeWithSelector(staking.withdraw.selector, tokenIds[0])
        );

        vm.stopPrank();
    }

    function testUserCannotWithdrawIfNotOwnerOrIfPaused()
        external
        mintAndStake(bob, 1)
    {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.prank(alice);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );
        vm.warp(block.timestamp + config.getUnbondingPeriod());
        vm.expectRevert();
        (bool success, ) = address(proxy).call(
            abi.encodeWithSelector(staking.withdraw.selector, tokenIds[0])
        );
        vm.startPrank(bob);
        vm.expectRevert();
        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.withdraw.selector, tokenIds[0])
        );
    }

    function testUserCanClaimRewards() external {
        for (uint i; i < 2; i++) {
            _mintAndStake(bob, i);
        }

        rewardToken.mint(address(proxy), 1e6 * 1e18);

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + config.getDelayPeriod());

        vm.startPrank(bob);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.claimRewards.selector, 1)
        );
        assertEq(rewardToken.balanceOf(bob), 10 * config.getRewardPerBlock());

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + config.getDelayPeriod());

        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.claimRewards.selector, 1)
        );

        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.claimRewards.selector, 0)
        );
        vm.stopPrank();
        assertEq(rewardToken.balanceOf(bob), 40 * config.getRewardPerBlock());
    }

    function testUserCannotClaimRewardsIfDelayPeriod() external {
        _mintAndStake(bob, 1);
        rewardToken.mint(address(proxy), 1e6 * 1e18);

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + config.getDelayPeriod() - 1);

        vm.startPrank(bob);
        vm.expectRevert();
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.claimRewards.selector, 1)
        );
        vm.stopPrank();
    }

    function testUserCannotClaimRewardsIfNotOwner() external {
        _mintAndStake(bob, 1);
        rewardToken.mint(address(proxy), 1e6 * 1e18);

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + config.getDelayPeriod());

        vm.startPrank(alice);
        vm.expectRevert();
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.claimRewards.selector, 1)
        );
        vm.stopPrank();
    }

    function testUserDoesNotGetRewardsAfterUnstaking() external {
        _mintAndStake(bob, 1);
        rewardToken.mint(address(proxy), 1e6 * 1e18);

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + config.getDelayPeriod());

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.startPrank(bob);
        (bool ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.unstake.selector, tokenIds)
        );
        require(ok);

        vm.roll(block.number + 10);

        (ok, ) = address(proxy).call(
            abi.encodeWithSelector(staking.claimRewards.selector, 1)
        );
        require(ok);

        assertEq(rewardToken.balanceOf(bob), 10 * config.getRewardPerBlock());
    }

    function testUserCanGetPendingRewards() external {
        _mintAndStake(bob, 1);
        rewardToken.mint(address(proxy), 1e6 * 1e18);

        vm.roll(block.number + 10);
        vm.warp(block.timestamp + config.getDelayPeriod());

        (bool ok, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(staking.getPendingRewards.selector, 1)
        );
        uint256 pending = abi.decode(data, (uint256));
        assertEq(pending, 10 * config.getRewardPerBlock());
    }

    function testRewardsAreDistributedCorrectly() external {
        config.setRewardPerBlock(10e18);
        _mintAndStake(bob, 1);
        // 1 hour = 1 block
        vm.roll(block.number + (29 * 24));
        vm.warp(block.timestamp + 29 days);
        _mintAndStake(alice, 2);
        vm.roll(block.number + (30 * 24));
        vm.warp(block.timestamp + 30 days);
        config.setRewardPerBlock(20e18);
        vm.roll(block.number + (60 * 24));
        vm.warp(block.timestamp + 60 days);

        (bool ok, bytes memory data) = address(proxy).call(
            abi.encodeWithSelector(staking.getPendingRewards.selector, 1)
        );
        require(ok);
        uint256 userArewards = abi.decode(data, (uint256));
        assertEq(userArewards, (240 * 59 + 480 * 60) * 1e18);
        console.log(userArewards);
        (ok, data) = address(proxy).call(
            abi.encodeWithSelector(staking.getPendingRewards.selector, 2)
        );
        require(ok);
        uint256 userBrewards = abi.decode(data, (uint256));
        assertEq(userBrewards, (240 * 30 + 480 * 60) * 1e18);
        console.log(userBrewards);

        vm.roll(block.number + (60 * 24));
        vm.warp(block.timestamp + 60 days);

        config.setRewardPerBlock(30e18);

        vm.roll(block.number + (180 * 24));
        vm.warp(block.timestamp + 180 days);

        (ok, data) = address(proxy).call(
            abi.encodeWithSelector(staking.getPendingRewards.selector, 1)
        );
        require(ok);
        userArewards = abi.decode(data, (uint256));
        assertEq(userArewards, (240 * 59 + 480 * 60 + 480 * 60 + 720 * 180) * 1e18);
        console.log(userArewards);
        (ok, data) = address(proxy).call(
            abi.encodeWithSelector(staking.getPendingRewards.selector, 2)
        );
        require(ok);
        userBrewards = abi.decode(data, (uint256));
        assertEq(userBrewards, (240 * 30 + 480 * 60 + 480 * 60 + 720 * 180) * 1e18);
        console.log(userBrewards);

    }
}
