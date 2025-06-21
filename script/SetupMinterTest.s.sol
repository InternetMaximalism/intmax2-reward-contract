// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Minter} from "../src/minter/Minter.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {INTMAXToken} from "../src/token/mainnet/INTMAXToken.sol";
import {DeployINTMAXToken} from "./DeployINTMAXToken.s.sol";
import {DeployMinter} from "./DeployMinter.s.sol";

/**
 * @title DeployMinter
 * @notice Script to deploy the Minter contract with a proxy
 * @dev This script deploys the Minter implementation and a proxy pointing to it
 */
contract SetupMinterTest is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address liquidity_address = vm.envAddress("LIQUIDITY_ADDRESS");
        address token_manager_address = vm.envAddress("TOKEN_MANAGER_ADDRESS");

        // convert private key to address
        address adminAddress = vm.addr(adminPrivateKey);

        // deploy token contract
        DeployINTMAXToken deployToken = new DeployINTMAXToken();
        INTMAXToken intmaxToken = deployToken.deploy(deployerPrivateKey, adminAddress, address(0));

        console.log("INTMAXToken deployed at:", address(intmaxToken));

        // deploy minter contract
        DeployMinter deployMinter = new DeployMinter();
        Minter minter = deployMinter.deploy(deployerPrivateKey, address(intmaxToken), liquidity_address, adminAddress);
        console.log("Minter deployed at:", address(minter));

        // start setup with admin private key
        vm.startBroadcast(adminPrivateKey);
        // grant minter role to the minter contract
        if (!intmaxToken.hasRole(intmaxToken.MINTER_ROLE(), address(minter))) {
            intmaxToken.grantRole(intmaxToken.MINTER_ROLE(), address(minter));
            console.log("Granted MINTER_ROLE to:", address(minter));
        }

        // grant minter role to the liquidity address
        if (!intmaxToken.hasRole(intmaxToken.MINTER_ROLE(), liquidity_address)) {
            intmaxToken.grantRole(intmaxToken.MINTER_ROLE(), liquidity_address);
            console.log("Granted MINTER_ROLE to liquidity address:", liquidity_address);
        }

        // set token manager role
        if (!minter.hasRole(minter.TOKEN_MANAGER_ROLE(), token_manager_address)) {
            minter.grantRole(minter.TOKEN_MANAGER_ROLE(), token_manager_address);
            console.log("Granted TOKEN_MANAGER_ROLE to:", token_manager_address);
        }

        vm.stopBroadcast();
    }
}
