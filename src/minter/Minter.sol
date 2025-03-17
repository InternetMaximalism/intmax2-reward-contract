// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IINTMAXToken} from "../token/IINTMAXToken.sol";
import {IL1GatewayRouter} from "@scroll-tech/contracts/L1/gateways/IL1GatewayRouter.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Minter is OwnableUpgradeable, UUPSUpgradeable {
    IINTMAXToken private intmaxToken;

    address private liquidity;
    address private blockBuilderReward;
    IL1GatewayRouter private l1GatewayRouter;

    function mintAndDistribute(
        uint256 amountToLiquidity,
        uint256 amountToBlockBuilderReward,
        uint256 rewardPeriod
    ) external {
        intmaxToken.mint(address(this));

        intmaxToken.transfer(liquidity, amountToLiquidity);

        l1GatewayRouter.depositERC20AndCall(
            address(intmaxToken),
            blockBuilderReward,
            amountToBlockBuilderReward,
            abi.encodeWithSignature(
                "deposit(uint256, uint256)",
                rewardPeriod,
                amountToBlockBuilderReward
            ),
            100_000_000_000 // todo set reasonable gas limit
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
