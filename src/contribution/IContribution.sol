// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IContribution {
    /// @notice Emitted when the period interval is zero
    error periodIntervalZero();

    /// @notice Emitted when a contribution is recorded.
    /// @param periodNumber The number of the period.
    /// @param tag The tag associated with the contribution.
    /// @param user The address of the user making the contribution.
    /// @param amount The amount of the contribution.
    event ContributionRecorded(
        uint256 indexed periodNumber,
        bytes32 indexed tag,
        address indexed user,
        uint256 amount
    );

    /// @notice Gets the current period
    /// @return The current period
    function getCurrentPeriod() external view returns (uint256);

    /// @notice Record a contribution for a specific tag and user.
    /// @param tag The tag associated with the contribution.
    /// @param user The address of the user making the contribution.
    /// @param amount The amount of contribution to record.
    function recordContribution(
        bytes32 tag,
        address user,
        uint256 amount
    ) external;

    /// @notice Returns the total contribution for a specific tag in the specified period
    /// @param period The period for which the contribution is being queried
    /// @param tag The tag (as bytes32) for which the contribution is being queried
    /// @return The unweighted total contribution amount as a uint256
    function totalContributions(
        uint256 period,
        bytes32 tag
    ) external view returns (uint256);

    /// @notice Returns the current contribution of a user for a specific tag in the specified period
    /// @param period The period for which the contribution is being queried
    /// @param tag The tag (as bytes32) for which the contribution is being queried
    /// @param user The address of the user whose contribution is being queried
    /// @return The unweighted contribution amount as a uint256
    function userContributions(
        uint256 period,
        bytes32 tag,
        address user
    ) external view returns (uint256);
}
