// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IMinter {
    /// @notice address is zero address
    error AddressZero();

    function mintAndDistribute(
        uint256 amountToLiquidity,
        uint256 amountToBlockBuilderReward,
        uint256 rewardPeriod
    ) external;
}
