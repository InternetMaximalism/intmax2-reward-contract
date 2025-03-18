// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IMinter} from "./IMinter.sol";
import {IINTMAXToken} from "../token/IINTMAXToken.sol";
import {IL1GatewayRouter} from "@scroll-tech/contracts/L1/gateways/IL1GatewayRouter.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Minter is IMinter, OwnableUpgradeable, UUPSUpgradeable {
    IINTMAXToken private intmaxToken;

    address private liquidity;
    address private blockBuilderReward;
    IL1GatewayRouter private l1GatewayRouter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with required dependencies
     * @param _intmaxToken Address of the INTMAX token
     * @param _liquidity Address for liquidity distribution
     * @param _blockBuilderReward Address of the BlockBuilderReward contract
     * @param _l1GatewayRouter Address of the L1GatewayRouter contract
     */
    function initialize(
        address _intmaxToken,
        address _liquidity,
        address _blockBuilderReward,
        address _l1GatewayRouter
    ) external initializer {
        if (
            _intmaxToken == address(0) ||
            _liquidity == address(0) ||
            _blockBuilderReward == address(0) ||
            _l1GatewayRouter == address(0)
        ) {
            revert AddressZero();
        }

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        intmaxToken = IINTMAXToken(_intmaxToken);
        liquidity = _liquidity;
        blockBuilderReward = _blockBuilderReward;
        l1GatewayRouter = IL1GatewayRouter(_l1GatewayRouter);
    }

    function mintAndDistribute(
        uint256 amountToLiquidity,
        uint256 amountToBlockBuilderReward,
        uint256 rewardPeriod
    ) external onlyOwner {
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
