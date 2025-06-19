// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {INTMAXToken} from "../src/token/mainnet/INTMAXToken.sol";

/**
 * @title DeployINTMAXToken
 * @notice Script to deploy the INTMAXToken contract
 * @dev This script deploys the INTMAXToken contract with admin and minter addresses
 */
contract DeployINTMAXToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address minter = address(0);

        INTMAXToken intmaxToken = deploy(deployerPrivateKey, admin, minter);

        console.log("INTMAXToken deployed at:", address(intmaxToken));
        console.log("Admin address:", admin);
        console.log("Minter address:", minter);
    }

    function deploy(uint256 deployerPrivateKey, address admin, address minter) public returns (INTMAXToken) {
        vm.startBroadcast(deployerPrivateKey);

        INTMAXToken intmaxToken = new INTMAXToken(admin, minter);

        vm.stopBroadcast();
        return intmaxToken;
    }
}
