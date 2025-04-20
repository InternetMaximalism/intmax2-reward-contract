// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {DeployScrollINTMAXToken} from "./DeployScrollINTMAXToken.s.sol";
import {DeployBlockBuilderReward} from "./DeployBlockBuilderReward.s.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";
import {BlockBuilderReward} from "../src/block-builder-reward/BlockBuilderReward.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployAll
 * @notice Script to deploy both ScrollINTMAXToken and BlockBuilderReward contracts
 * @dev This script deploys both contracts in sequence and configures them to work together
 */
contract DeployAll is Script {
    function run() public {
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address contributionContract = vm.envAddress(
            "CONTRIBUTION_CONTRACT_ADDRESS"
        );
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");

        vm.startBroadcast();
        deploy(admin, contributionContract, initialSupply);
        vm.stopBroadcast();
    }

    function deploy(
        address admin,
        address contributionContract,
        uint256 initialSupply
    ) public {
        console.log("Starting deployment of all contracts");
        console.log("Admin address:", admin);
        console.log("Contribution contract address:", contributionContract);
        console.log("Initial supply:", initialSupply);

        // deploy token
        DeployScrollINTMAXToken deployToken = new DeployScrollINTMAXToken();
        ScrollINTMAXToken token = deployToken.deploy();

        // deploy reward
        DeployBlockBuilderReward deployReward = new DeployBlockBuilderReward();
        BlockBuilderReward reward = deployReward.deploy(
            contributionContract,
            address(token)
        );

        // initialize token
        token.initialize(admin, address(reward), initialSupply);

        console.log("All contracts deployed successfully");
        console.log("Summary:");
        console.log("- ScrollINTMAXToken: ", address(token));
        console.log("- BlockBuilderReward: ", address(reward));
    }
}
