// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";

/**
 * @title DeployScrollINTMAXToken
 * @notice Script to deploy the ScrollINTMAXToken contract
 * @dev This script deploys the ScrollINTMAXToken contract with the specified parameters
 */
contract DeployScrollINTMAXToken is Script {
    function run() public returns (ScrollINTMAXToken) {
        address admin = vm.envAddress("ADMIN");
        address rewardContract = vm.envAddress("REWARD_CONTRACT");
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");

        // Log deployment parameters
        console.log(
            "Deploying ScrollINTMAXToken with the following parameters:"
        );
        console.log("Admin address:", admin);
        console.log("Reward contract address:", rewardContract);
        console.log("Initial supply:", initialSupply);

        vm.startBroadcast();

        // Deploy the ScrollINTMAXToken contract
        ScrollINTMAXToken token = new ScrollINTMAXToken(
            admin,
            rewardContract,
            initialSupply
        );

        vm.stopBroadcast();

        // Log the deployed contract address
        console.log("ScrollINTMAXToken deployed at:", address(token));

        return token;
    }
}
