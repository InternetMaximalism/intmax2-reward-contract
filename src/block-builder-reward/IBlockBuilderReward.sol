// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/**
 * @title IBlockBuilderReward
 * @notice Interface for the BlockBuilderReward contract which manages rewards for block builders
 * @dev This contract handles the distribution of rewards to users who contribute to block building
 * based on their contribution scores from the Contribution contract
 */
interface IBlockBuilderReward {
    /// @notice Error thrown when an address parameter is the zero address
    error AddressZero();

    /// @notice Error thrown when a user tries to claim a reward that has already been claimed
    error AlreadyClaimed();

    /// @notice Error thrown when a user tries to claim a reward with zero amount
    error TriedToClaimZeroReward();

    /// @notice Error thrown when owner tries to set a reward that has already been set
    error AlreadySetReward();

    /// @notice Error thrown when owner tries to set a reward that is bigger than 2^248
    error RewardTooLarge();

    /// @notice Error thrown when a user tries to claim a reward for a period that has not ended
    error PeriodNotEnded();

    /// @notice Error thrown when a reward is not set for a given period
    error NotSetReward();

    /// @notice Emitted when a reward is set.
    event SetReward(uint256 indexed periodNumber, uint256 amount);

    /// @notice Emitted when a reward is claimed.
    event Claimed(uint256 indexed periodNumber, address indexed user, uint256 amount);

    /**
     * @notice Structure to store reward information for a specific period
     * @param isSet Boolean indicating if the reward has been set for this period
     * @param amount The total reward amount for the period (limited to uint248 to pack it in a single slot)
     */
    struct TotalReward {
        bool isSet;
        uint248 amount;
    }

    /**
     * @notice Sets the total reward amount for a specific period
     * @dev Only callable by accounts with the REWARD_MANAGER_ROLE
     * @param periodNumber The period number for which the reward is being set
     * @param amount The total amount of tokens to distribute as rewards for the given period
     * @custom:throws AlreadySetReward if reward for this period has already been set
     * @custom:throws RewardTooLarge if amount exceeds uint248 max value
     */
    function setReward(uint256 periodNumber, uint256 amount) external;

    /**
     * @notice Retrieves the reward information for a specific period
     * @dev Returns whether a reward has been set and the reward amount for the given period
     * @param periodNumber The period number for which to retrieve reward information
     * @return A tuple containing:
     *         - A boolean indicating whether a reward has been set for the period
     *         - The total reward amount for the period (returns 0 if not set)
     */
    function getReward(uint256 periodNumber) external view returns (bool, uint256);

    /**
     * @notice Retrieves the current period number from the Contribution contract
     * @dev This is a pass-through function to the Contribution contract's getCurrentPeriod function
     * @return The current period number
     */
    function getCurrentPeriod() external view returns (uint256);

    /**
     * @notice Claims the caller's share of rewards for a specific period
     * @dev The reward amount is calculated based on the user's contribution relative to the total contributions
     * @param periodNumber The period number for which the reward is being claimed
     * @custom:throws PeriodNotEnded if the specified period has not yet ended
     * @custom:throws NotSetReward if no reward has been set for the specified period
     * @custom:throws AlreadyClaimed if the caller has already claimed their reward for this period
     */
    function claimReward(uint256 periodNumber) external;

    /**
     * @notice Claims the caller's share of rewards for multiple periods in a single transaction
     * @dev Calls claimReward for each period number in the array
     * @param periodNumbers An array of period numbers for which rewards are being claimed
     * @custom:throws PeriodNotEnded if any specified period has not yet ended
     * @custom:throws NotSetReward if no reward has been set for any specified period
     * @custom:throws AlreadyClaimed if the caller has already claimed their reward for any period
     */
    function batchClaimReward(uint256[] calldata periodNumbers) external;

    /**
     * @notice Calculates the claimable reward amount for a specific user and period
     * @dev The reward amount is calculated based on the user's contribution relative to the total contributions
     * for the specified period and tag. Returns 0 if the period has not ended, no reward has been set,
     * or the user has already claimed their reward.
     * @param periodNumber The period number for which to calculate the claimable reward
     * @param user The address of the user for whom to calculate the claimable reward
     * @return The amount of tokens the user can claim as reward for the specified period
     */
    function getClaimableReward(uint256 periodNumber, address user) external view returns (uint256);
}
