// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IBlockBuilderReward {
    /// @notice address is zero address
    error AddressZero();

    /// @notice Error thrown when a non-ScrollMessenger calls a function restricted to ScrollMessenger
    error OnlyScrollMessenger();

    /// @notice Error thrown when the xDomainMessageSender in ScrollMessenger is not the Minter contract
    error OnlyMinter();

    event ITXDeposited(uint256 indexed periodNumber, uint256 amount);

    event ITXClaimed(
        uint256 indexed periodNumber,
        address indexed user,
        uint256 amount
    );
}
