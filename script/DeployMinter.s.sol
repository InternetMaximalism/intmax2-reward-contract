// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Minter} from "../src/minter/Minter.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployMinter
 * @notice Script to deploy the Minter contract with a proxy
 * @dev This script deploys the Minter implementation and a proxy pointing to it
 */
contract DeployMinter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address intmaxToken = vm.envAddress("INTMAX_TOKEN_ADDRESS");
        address liquidity = vm.envAddress("LIQUIDITY_ADDRESS");

        Minter minter = deploy(deployerPrivateKey, intmaxToken, liquidity, admin);

        console.log("Minter implementation deployed at:", address(minter));
        console.log("Minter proxy deployed at:", address(minter));
    }

    function deploy(uint256 deployerPrivateKey, address intmaxToken, address liquidity, address admin)
        public
        returns (Minter)
    {
        vm.startBroadcast(deployerPrivateKey);

        Minter implementation = new Minter();

        // Prepare the initialization data
        bytes memory initData = abi.encodeWithSelector(Minter.initialize.selector, intmaxToken, liquidity, admin);

        // Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Create a reference to the proxied Minter for easier interaction
        Minter minter = Minter(address(proxy));
        vm.stopBroadcast();
        return minter;
    }
}
