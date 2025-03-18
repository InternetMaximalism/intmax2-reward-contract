// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IBlockBuilderReward {
    /// @notice address is zero address
    error AddressZero();

    /// @notice Error thrown when a non-ScrollMessenger calls a function restricted to ScrollMessenger
    error OnlyScrollMessenger();

    /// @notice Error thrown when the xDomainMessageSender in ScrollMessenger is not the Minter contract
    error OnlyMinter();

    /// @notice Error thrown when a user tries to claim a reward that has already been claimed
    error AlreadyClaimed();

    /// @notice Error thrown when a user tries to claim a reward for a period that has not ended
    error PeriodNotEnded();

    event Deposited(uint256 indexed periodNumber, uint256 amount);

    event Claimed(
        uint256 indexed periodNumber,
        address indexed user,
        uint256 amount
    );
}
