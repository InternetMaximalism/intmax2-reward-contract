// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {DeployScrollINTMAXToken} from "./DeployScrollINTMAXToken.s.sol";
import {DeployBlockBuilderReward} from "./DeployBlockBuilderReward.s.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";
import {BlockBuilderReward} from "../src/block-builder-reward/BlockBuilderReward.sol";
import {TestContribution} from "../test/block-builder-reward/BlockBuilderReward.t.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SetupTestContracts is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        // deploy test contribution contract
        vm.startBroadcast(deployerPrivateKey);
        TestContribution testContribution = new TestContribution();

        vm.stopBroadcast();

        // deploy token
        DeployScrollINTMAXToken deployToken = new DeployScrollINTMAXToken();
        ScrollINTMAXToken token = deployToken.deploy(deployerPrivateKey);

        // deploy reward
        DeployBlockBuilderReward deployReward = new DeployBlockBuilderReward();
        BlockBuilderReward reward = deployReward.deploy(
            deployerPrivateKey, deployerAddress, deployerAddress, address(testContribution), address(token)
        );

        vm.startBroadcast(deployerPrivateKey);

        // initialize token
        token.initialize(deployerAddress, address(reward), 9e25);

        // set the current period in the test contribution contract
        bytes32 blockPostTag = keccak256("POST_BLOCK");
        testContribution.setUserContribution(1, blockPostTag, deployerAddress, 100);
        testContribution.setTotalContribution(1, blockPostTag, 1000);
        testContribution.setUserContribution(2, blockPostTag, deployerAddress, 200);
        testContribution.setTotalContribution(2, blockPostTag, 2000);
        testContribution.setCurrentPeriod(3);

        // set the reward
        reward.setReward(1, 100000);
        reward.setReward(2, 200000);
        vm.stopBroadcast();

        console.logBytes32(blockPostTag);
        console.log("All contracts deployed successfully");
        console.log("Summary:");
        console.log("- TestContribution: ", address(testContribution));
        console.log("- ScrollINTMAXToken: ", address(token));
        console.log("- BlockBuilderReward: ", address(reward));
    }
}
