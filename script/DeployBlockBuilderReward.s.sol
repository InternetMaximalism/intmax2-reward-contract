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
    function deploy(
        uint256 deployerPrivateKey,
        address admin,
        address rewardManager,
        address contributionContract,
        address intmaxToken
    ) public returns (BlockBuilderReward) {
        vm.startBroadcast(deployerPrivateKey);

        BlockBuilderReward implementation = new BlockBuilderReward();

        // Prepare the initialization data
        bytes memory initData = abi.encodeWithSelector(
            BlockBuilderReward.initialize.selector, admin, rewardManager, contributionContract, intmaxToken
        );

        // Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Create a reference to the proxied BlockBuilderReward for easier interaction
        BlockBuilderReward blockBuilderReward = BlockBuilderReward(address(proxy));
        vm.stopBroadcast();
        return blockBuilderReward;
    }
}
