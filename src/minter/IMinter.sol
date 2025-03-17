// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IMinter {
    function mintAndDistribute(
        uint256 amountToLiquidity,
        uint256 amountToBlockBuilderReward,
        uint256 rewardPeriod
    ) external;
}
