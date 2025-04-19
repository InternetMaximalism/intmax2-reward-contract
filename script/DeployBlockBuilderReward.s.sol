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
    // Default values that can be overridden via command-line arguments
    address public contributionContract = address(0x3);
    address public intmaxToken = address(0x4);

    function setUp() public {
        // These values can be overridden via command-line arguments
        // Example: forge script script/DeployBlockBuilderReward.s.sol --sig "run(address,address)" <contributionContract> <intmaxToken>
    }

    // Alternative run function that allows overriding parameters
    function run(
        address _contributionContract,
        address _intmaxToken
    ) public returns (address) {
        contributionContract = _contributionContract;
        intmaxToken = _intmaxToken;
        return run();
    }

    function run() public returns (address) {
        // Log deployment parameters
        console.log(
            "Deploying BlockBuilderReward with the following parameters:"
        );
        console.log("Contribution contract address:", contributionContract);
        console.log("INTMAX token address:", intmaxToken);

        vm.startBroadcast();

        // Deploy the implementation contract
        BlockBuilderReward implementation = new BlockBuilderReward();
        console.log(
            "BlockBuilderReward implementation deployed at:",
            address(implementation)
        );

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
        console.log("BlockBuilderReward proxy deployed at:", address(proxy));

        // Create a reference to the proxied BlockBuilderReward for easier interaction
        BlockBuilderReward blockBuilderReward = BlockBuilderReward(
            address(proxy)
        );

        vm.stopBroadcast();

        console.log("BlockBuilderReward deployment completed");

        return address(proxy);
    }
}
