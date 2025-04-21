// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {DeployScrollINTMAXToken} from "./DeployScrollINTMAXToken.s.sol";
import {DeployBlockBuilderReward} from "./DeployBlockBuilderReward.s.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";
import {BlockBuilderReward} from "../src/block-builder-reward/BlockBuilderReward.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeBlockBuilderReward is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address blockBuilderRewardAddress = vm.envAddress("BLOCK_BUILDER_REWARD_ADDRESS");
        address adminAddress = vm.addr(adminPrivateKey);
        console.log("Admin address:", adminAddress);
        console.log("BlockBuilderReward address:", blockBuilderRewardAddress);

        vm.startBroadcast(deployerPrivateKey);
        // deploy new implementation
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.stopBroadcast();

        // upgrade the proxy to the new implementation
        vm.startBroadcast(adminPrivateKey);
        BlockBuilderReward proxy = BlockBuilderReward(blockBuilderRewardAddress);
        proxy.upgradeToAndCall(address(implementation), new bytes(0));
        vm.stopBroadcast();
    }
}
