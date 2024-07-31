// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {NFTStaking} from "../../src/NFTStaking.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTStakingMock is UUPSUpgradeable {
    function getVersion() external view returns (uint256) {
        return 2;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}