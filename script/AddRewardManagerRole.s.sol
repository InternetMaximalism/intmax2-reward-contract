// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {BlockBuilderReward} from "../src/block-builder-reward/BlockBuilderReward.sol";

contract AddRewardManagerRole is Script {
    function run() public {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address blockBuilderRewardAddress = vm.envAddress("BLOCK_BUILDER_REWARD_ADDRESS");
        address rewardManagerAddress = vm.envAddress("REWARD_MANAGER_ADDRESS");

        console.log("Admin address:", vm.addr(adminPrivateKey));
        console.log("BlockBuilderReward address:", blockBuilderRewardAddress);
        console.log("Reward manager address:", rewardManagerAddress);

        vm.startBroadcast(adminPrivateKey);
        BlockBuilderReward proxy = BlockBuilderReward(blockBuilderRewardAddress);
        proxy.grantRole(proxy.REWARD_MANAGER_ROLE(), rewardManagerAddress);
        vm.stopBroadcast();
    }
}
