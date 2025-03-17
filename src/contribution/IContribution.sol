// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {UD60x18} from "@prb/math/src/UD60x18.sol";

interface IContribution {
	/// @notice Emitted when the current period is incremented.
	/// @param newPeriod The new period number.
	event PeriodIncremented(uint256 indexed newPeriod);

	/// @notice Emitted when weights are registered for a period.
	/// @param periodNumber The number of the period.
	/// @param tags An array of bytes32 representing the tags.
	/// @param weights An array of uint256 representing the weights.
	event WeightRegistered(
		uint256 indexed periodNumber,
		bytes32[] tags,
		uint256[] weights
	);

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

	/// @notice Error thrown when the input lengths of tags and weights do not match in registerWeights function
	/// @dev This error is raised to ensure data integrity when registering weights for tags
	error InvalidInputLength();

	/// @notice Get the list of tags registered for a specific period.
	/// @param periodNumber The number of the period to query.
	/// @return An array of bytes32 representing the tags.
	function getTags(
		uint256 periodNumber
	) external view returns (bytes32[] memory);

	/// @notice Get the weights array for a specified period.
	/// @param periodNumber The number of the period to query.
	/// @return An array of uint256 representing the weights.
	function getWeights(
		uint256 periodNumber
	) external view returns (uint256[] memory);

	/// @notice Register tags and their corresponding weights for a period.
	/// @param periodNumber The number of the period to register for.
	/// @param tags An array of bytes32 representing the tags.
	/// @param weights An array of uint256 representing the weights corresponding to the tags.
	function registerWeights(
		uint256 periodNumber,
		bytes32[] memory tags,
		uint256[] memory weights
	) external;

	/// @notice Increment the current period number.
	function incrementPeriod() external;

	/// @notice Record a contribution for a specific tag and user.
	/// @param tag The tag associated with the contribution.
	/// @param user The address of the user making the contribution.
	/// @param amount The amount of contribution to record.
	function recordContribution(
		bytes32 tag,
		address user,
		uint256 amount
	) external;

	/// @notice Returns the current contribution of a user for a specific tag in the current period
	/// @dev This function does not apply any weighting to the contribution
	/// @param tag The tag (as bytes32) for which the contribution is being queried
	/// @param user The address of the user whose contribution is being queried
	/// @return The unweighted contribution amount as a uint256
	function getCurrentContribution(
		bytes32 tag,
		address user
	) external view returns (uint256);

	/// @notice Get the contribution rate of a specific user for a given period.
	/// @param periodNumber The number of the period to query.
	/// @param user The address of the user to check.
	/// @return The contribution rate as a UD60x18 value, representing the user's share of the total contribution.
	function getContributionRate(
		uint256 periodNumber,
		address user
	) external view returns (UD60x18);
}
