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
    // Default values that can be overridden via command-line arguments
    address public admin = address(0x1);
    address public contributionContract = address(0x3);
    uint256 public initialSupply = 1_000_000_000 * 10**18; // 1 billion tokens with 18 decimals

    function setUp() public {
        // These values can be overridden via command-line arguments
        // Example: forge script script/DeployAll.s.sol --sig "run(address,address,uint256)" <admin> <contributionContract> <initialSupply>
    }

    // Alternative run function that allows overriding parameters
    function run(address _admin, address _contributionContract, uint256 _initialSupply) public returns (address, address) {
        admin = _admin;
        contributionContract = _contributionContract;
        initialSupply = _initialSupply;
        return run();
    }

    function run() public returns (address, address) {
        console.log("Starting deployment of all contracts");
        console.log("Admin address:", admin);
        console.log("Contribution contract address:", contributionContract);
        console.log("Initial supply:", initialSupply);

        vm.startBroadcast();

        // Step 1: Deploy the BlockBuilderReward implementation contract first
        // (We'll initialize it later with the token address)
        BlockBuilderReward implementation = new BlockBuilderReward();
        console.log("BlockBuilderReward implementation deployed at:", address(implementation));

        // Step 2: Deploy the ScrollINTMAXToken
        // The rewardContract parameter will be the proxy address of BlockBuilderReward
        // We'll deploy the token first with a temporary address and then update it
        ScrollINTMAXToken token = new ScrollINTMAXToken(
            admin,
            address(0), // Temporary address, will be updated after proxy deployment
            initialSupply
        );
        console.log("ScrollINTMAXToken deployed at:", address(token));

        // Step 3: Deploy the BlockBuilderReward proxy
        bytes memory initData = abi.encodeWithSelector(
            BlockBuilderReward.initialize.selector,
            contributionContract,
            address(token)
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("BlockBuilderReward proxy deployed at:", address(proxy));

        // Step 4: Create a reference to the proxied BlockBuilderReward for easier interaction
        BlockBuilderReward blockBuilderReward = BlockBuilderReward(address(proxy));

        // Step 5: Deploy a new token with the correct reward contract address
        // Note: This is necessary because we can't update the DISTRIBUTOR role in the token after deployment
        ScrollINTMAXToken finalToken = new ScrollINTMAXToken(
            admin,
            address(proxy), // Now we use the actual proxy address
            initialSupply
        );
        console.log("Final ScrollINTMAXToken deployed at:", address(finalToken));

        vm.stopBroadcast();

        console.log("All contracts deployed successfully");
        console.log("Summary:");
        console.log("- ScrollINTMAXToken: ", address(finalToken));
        console.log("- BlockBuilderReward (proxy): ", address(proxy));
        console.log("- BlockBuilderReward (implementation): ", address(implementation));
        
        // Return the addresses of the deployed contracts
        return (address(finalToken), address(proxy));
    }
}
