// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";

/**
 * @title DeployScrollINTMAXToken
 * @notice Script to deploy the ScrollINTMAXToken contract
 * @dev This script deploys the ScrollINTMAXToken contract with the specified parameters
 */
contract DeployScrollINTMAXToken is Script {
    // Default values that can be overridden via command-line arguments
    address public admin = address(0x1);
    address public rewardContract = address(0x2);
    uint256 public initialSupply = 1_000_000_000 * 10**18; // 1 billion tokens with 18 decimals

    function setUp() public {
        // These values can be overridden via command-line arguments
        // Example: forge script script/DeployScrollINTMAXToken.s.sol --sig "run(address,address,uint256)" <admin> <rewardContract> <initialSupply>
    }

    // Alternative run function that allows overriding parameters
    function run(address _admin, address _rewardContract, uint256 _initialSupply) public returns (ScrollINTMAXToken) {
        admin = _admin;
        rewardContract = _rewardContract;
        initialSupply = _initialSupply;
        return run();
    }

    function run() public returns (ScrollINTMAXToken) {
        // Log deployment parameters
        console.log("Deploying ScrollINTMAXToken with the following parameters:");
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
