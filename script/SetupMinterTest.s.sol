// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Minter} from "../src/minter/Minter.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {INTMAXToken} from "../src/token/mainnet/INTMAXToken.sol";

/**
 * @title DeployMinter
 * @notice Script to deploy the Minter contract with a proxy
 * @dev This script deploys the Minter implementation and a proxy pointing to it
 */
contract SetupMinterTest is Script {
    function run() external {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

        address token_address = vm.envAddress("INTMAX_TOKEN_ADDRESS");
        address minter_address = vm.envAddress("MINTER_ADDRESS");
        address liquidity_address = vm.envAddress("LIQUIDITY_ADDRESS");
        address token_manager_address = vm.envAddress("TOKEN_MANAGER_ADDRESS");

        vm.startBroadcast(adminPrivateKey);

        INTMAXToken intmaxToken = INTMAXToken(token_address);
        Minter minter = Minter(minter_address);

        // grant minter role to the minter contract
        if (!intmaxToken.hasRole(intmaxToken.MINTER_ROLE(), minter_address)) {
            intmaxToken.grantRole(intmaxToken.MINTER_ROLE(), minter_address);
            console.log("Granted MINTER_ROLE to:", minter_address);
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
