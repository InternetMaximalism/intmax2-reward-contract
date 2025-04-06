// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IBlockBuilderReward {
    /// @notice address is zero address
    error AddressZero();

    /// @notice Error thrown when a user tries to claim a reward that has already been claimed
    error AlreadyClaimed();

    /// @notice Error thrown when a user tries to claim a reward that is not allowed
    error ClaimNotAllowed();

    /// @notice Error thrown when owner tries to set a reward for a period that has already allowed claim
    error ClaimAllowed();

    /// @notice Error thrown when a user tries to claim a reward for a period that has not ended
    error PeriodNotEnded();

    /// @notice Emitted when a reward is set.
    event SetReward(uint256 indexed periodNumber, uint256 amount);

    /// @notice Emitted when a reward is claimed.
    event Claimed(uint256 indexed periodNumber, address indexed user, uint256 amount);

    function setReward(uint256 periodNumber, uint256 amount) external;

    function allowClaim(uint256 periodNumber) external;

    function claimReward(uint256 periodNumber) external;
}
