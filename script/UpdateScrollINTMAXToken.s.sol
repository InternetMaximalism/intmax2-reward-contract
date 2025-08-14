// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {ScrollINTMAXToken} from "../src/token/scroll/ScrollINTMAXToken.sol";

/**
 * @title UpdateScrollINTMAXToken
 * @notice Script to update the ScrollINTMAXToken contract
 * @dev This script updates the ScrollINTMAXToken contract
 */
contract UpdateScrollINTMAXToken is Script {
    function run() public {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        vm.startBroadcast(adminPrivateKey);

        // Deploy the 2nd impl contract
        ScrollINTMAXToken secondImpl = new ScrollINTMAXToken();
        console.log("2nd impl address:", address(secondImpl));

        address scrollIntmaxAddress = vm.envAddress("INTMAX_TOKEN_ADDRESS");
        ScrollINTMAXToken currentToken = ScrollINTMAXToken(scrollIntmaxAddress);

        // Upgrade the existing token contract
        currentToken.upgradeToAndCall(address(secondImpl), "");

        vm.stopBroadcast();
    }
}
