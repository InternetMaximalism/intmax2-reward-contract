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
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address rewardManagerAddress = vm.envAddress("REWARD_MANAGER_ADDRESS");
        address contributionContract = vm.envAddress("CONTRIBUTION_CONTRACT_ADDRESS");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");
        deploy(deployerPrivateKey, admin, rewardManagerAddress, contributionContract, initialSupply);
    }

    function deploy(
        uint256 deployerPrivateKey,
        address admin,
        address rewardManagerAddress,
        address contributionContract,
        uint256 initialSupply
    ) public {
        console.log("Starting deployment of all contracts");
        console.log("Admin address:", admin);
        console.log("Reward manager address:", rewardManagerAddress);
        console.log("Contribution contract address:", contributionContract);
        console.log("Initial supply:", initialSupply);

        // deploy token
        DeployScrollINTMAXToken deployToken = new DeployScrollINTMAXToken();
        ScrollINTMAXToken token = deployToken.deploy(deployerPrivateKey);

        // deploy reward
        DeployBlockBuilderReward deployReward = new DeployBlockBuilderReward();
        BlockBuilderReward reward =
            deployReward.deploy(deployerPrivateKey, admin, rewardManagerAddress, contributionContract, address(token));

        // initialize token
        vm.startBroadcast(deployerPrivateKey);
        token.initialize(admin, address(reward), initialSupply);
        vm.stopBroadcast();

        console.log("All contracts deployed successfully");
        console.log("Summary:");
        console.log("- ScrollINTMAXToken: ", address(token));
        console.log("- BlockBuilderReward: ", address(reward));
    }
}
