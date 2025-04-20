// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployScrollINTMAXToken
 * @notice Script to deploy the ScrollINTMAXToken contract
 * @dev This script deploys the ScrollINTMAXToken contract with the specified parameters
 */
contract DeployScrollINTMAXToken is Script {
    ScrollINTMAXToken public token;

    function deploy(uint256 deployerPrivateKey) public returns (ScrollINTMAXToken) {
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the implementation contract
        ScrollINTMAXToken implementation = new ScrollINTMAXToken();

        // Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), new bytes(0));

        token = ScrollINTMAXToken(address(proxy));

        vm.stopBroadcast();

        return token;
    }
}
