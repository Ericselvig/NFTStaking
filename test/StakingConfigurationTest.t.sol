// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StakingConfiguration} from "../src/StakingConfiguration.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

contract StakingConfigurationTest is Test {
    StakingConfiguration config;
    MockERC20 rewardToken;
    address bob;

    function setUp() public {
        config = new StakingConfiguration();
        rewardToken = new MockERC20();
        bob = makeAddr("bob");
    }

    function testOwnerCanSetRewardToken() public {
        config.setRewardToken(bob);
        assertEq(config.getRewardToken(), bob);
    }

    function testOwnerCanSetStakingNFT() public {
        config.setStakingNFT(bob);
        assertEq(config.getStakingNFT(), bob);
    }

    function testOwnerCanSetRewardPerBlock() public {
        config.setRewardPerBlock(100);
        assertEq(config.getRewardPerBlock(), 100);
    }

    function testOwnerCanSetDelayPeriod() public {
        config.setDelayPeriod(100);
        assertEq(config.getDelayPeriod(), 100);
    }

    function testOwnerCanSetUnbondingPeriod() public {
        config.setUnbondingPeriod(100);
        assertEq(config.getUnbondingPeriod(), 100);
    }

    function testNotOwnerCannotSetRewardToken() public {
        vm.prank(bob);
        vm.expectRevert();
        config.setRewardToken(address(rewardToken));
    }

    function testNotOwnerCannotSetStakingNFT() public {
        vm.prank(bob);
        vm.expectRevert();
        config.setStakingNFT(address(rewardToken));
    }

    function testNotOwnerCannotSetRewardPerBlock() public {
        vm.prank(bob);
        vm.expectRevert();
        config.setRewardPerBlock(100);
    }

    function testNotOwnerCannotSetDelayPeriod() public {
        vm.prank(bob);
        vm.expectRevert();
        config.setDelayPeriod(100);
    }

    function testNotOwnerCannotSetUnbondingPeriod() public {
        vm.prank(bob);
        vm.expectRevert();
        config.setUnbondingPeriod(100);
    }

    function testGetters() public {
        config.setRewardToken(bob);
        config.setStakingNFT(bob);
        config.setRewardPerBlock(100);
        config.setDelayPeriod(100);
        config.setUnbondingPeriod(100);

        assertEq(config.getRewardToken(), bob);
        assertEq(config.getStakingNFT(), bob);
        assertEq(config.getRewardPerBlock(), 100);
        assertEq(config.getDelayPeriod(), 100);
        assertEq(config.getUnbondingPeriod(), 100);
    }
}