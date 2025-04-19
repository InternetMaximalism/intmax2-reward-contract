// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IBlockBuilderReward {
    /// @notice address is zero address
    error AddressZero();

    /// @notice Error thrown when a user tries to claim a reward that has already been claimed
    error AlreadyClaimed();

    /// @notice Error thrown when owner tries to set a reward that has already been set
    error AlreadySetReward();

    /// @notice Error thrown when owner tries to set a reward that is bigger than 2^248
    error RewardTooLarge();

    /// @notice Error thrown when a user tries to claim a reward for a period that has not ended
    error PeriodNotEnded();

    /// @notice Error thrown when a reward is not set for a given period
    error NotSetReward(uint256 periodNumber);

    /// @notice Error thrown when trying to claim a reward for a period that does not have claim allowed
    error ClaimNotAllowed();

    /// @notice Emitted when a reward is set.
    event SetReward(uint256 indexed periodNumber, uint256 amount);

    /// @notice Emitted when a reward is claimed.
    event Claimed(
        uint256 indexed periodNumber,
        address indexed user,
        uint256 amount
    );

    struct TotalReward {
        bool isSet;
        uint248 amount;
    }

    /**
     * @notice Sets the reward for a given period
     * @dev Only callable by the contract owner
     * @param periodNumber The period number for which the reward is being set
     * @param amount The amount of reward to be set for the given period
     */
    function setReward(uint256 periodNumber, uint256 amount) external;

    /**
     * @notice Claims the reward for a given period
     * @dev Only callable by the user who is claiming the reward
     * @param periodNumber The period number for which the reward is being claimed
     */
    function claimReward(uint256 periodNumber) external;
}
