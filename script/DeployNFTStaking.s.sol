// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StakingConfiguration} from "../src/StakingConfiguration.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC721Mock} from "../test/mocks/ERC721Mock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployNFTStaking is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log("deployer: ", deployer);

        vm.startBroadcast(privateKey);

        ERC20Mock rewardToken = new ERC20Mock();
        ERC721Mock stakingNFT = new ERC721Mock();

        StakingConfiguration config = new StakingConfiguration();
        config.setRewardToken(address(rewardToken));
        config.setDelayPeriod(100);
        config.setUnbondingPeriod(100);
        config.setStakingNFT(address(stakingNFT));
        config.setRewardPerBlock(1e18);

        NFTStaking staking = new NFTStaking();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(staking),
            abi.encodeWithSignature("initialize(address)", address(config))
        );

        vm.stopBroadcast();

        console.log("NFTStaking proxy deployed at: ", address(proxy));
        console.log("StakingConfiguration deployed at: ", address(config));
    }
}
