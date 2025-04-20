// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {BlockBuilderReward} from "../src/block-builder-reward/BlockBuilderReward.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployBlockBuilderReward
 * @notice Script to deploy the BlockBuilderReward contract with a proxy
 * @dev This script deploys the BlockBuilderReward implementation and a proxy pointing to it
 */
contract DeployBlockBuilderReward is Script {
    function run(
        address contributionContract,
        address intmaxToken
    ) public returns (BlockBuilderReward) {
        return deploy(contributionContract, intmaxToken);
    }

    function run() public returns (BlockBuilderReward) {
        address contributionContract = vm.envAddress(
            "CONTRIBUTION_CONTRACT_ADDRESS"
        );
        address intmaxToken = vm.envAddress("INTMAX_TOKEN_ADDRESS");
        // Log deployment parameters
        console.log(
            "Deploying BlockBuilderReward with the following parameters:"
        );
        console.log("Contribution contract address:", contributionContract);
        console.log("INTMAX token address:", intmaxToken);

        vm.startBroadcast();

        BlockBuilderReward reward = deploy(contributionContract, intmaxToken);

        vm.stopBroadcast();

        console.log("BlockBuilderReward deployment completed");
        console.log("BlockBuilderReward deployed at:", address(reward));
        return reward;
    }

    function deploy(
        address contributionContract,
        address intmaxToken
    ) public returns (BlockBuilderReward) {
        BlockBuilderReward implementation = new BlockBuilderReward();

        // Prepare the initialization data
        bytes memory initData = abi.encodeWithSelector(
            BlockBuilderReward.initialize.selector,
            contributionContract,
            intmaxToken
        );

        // Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        // Create a reference to the proxied BlockBuilderReward for easier interaction
        BlockBuilderReward blockBuilderReward = BlockBuilderReward(
            address(proxy)
        );

        return blockBuilderReward;
    }
}
