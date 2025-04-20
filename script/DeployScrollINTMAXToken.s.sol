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

    function run() public {
        vm.startBroadcast();
        deploy();
        vm.stopBroadcast();
    }

    function deploy() public returns (ScrollINTMAXToken) {
        // Deploy the implementation contract
        ScrollINTMAXToken implementation = new ScrollINTMAXToken();
        console.log(
            "ScrollINTMAXToken implementation deployed at:",
            address(implementation)
        );

        // Deploy the proxy contract pointing to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            new bytes(0)
        );
        console.log("ScrollINTMAXToken proxy deployed at:", address(proxy));

        token = ScrollINTMAXToken(address(proxy));

        return token;
    }

    function initialize(
        address admin,
        address rewardContract,
        uint256 initialSupply
    ) public {
        console.log(
            "Initializing ScrollINTMAXToken with the following parameters:"
        );
        console.log("Admin address:", admin);
        console.log("Reward contract address:", rewardContract);
        console.log("Initial supply:", initialSupply);

        token.initialize(admin, rewardContract, initialSupply);
    }
}
