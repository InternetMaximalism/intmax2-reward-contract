// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import {UD60x18, convert} from "@prb/math/src/UD60x18.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IContribution} from "./IContribution.sol";

contract Contribution is
	IContribution,
	UUPSUpgradeable,
	AccessControlUpgradeable
{
	/// @notice Role identifier for administers who can register weights
	bytes32 public constant WEIGHT_REGISTRAR = keccak256("WEIGHT_REGISTRAR");

	/// @notice Role identifier for contracts that can record contributions
	bytes32 public constant CONTRIBUTOR = keccak256("CONTRIBUTOR");

	/// @notice The current active period for contributions
	uint256 public currentPeriod;

	/// @notice Maps periods and tags to total contributions
	/// @dev period => tag => total contribution amount
	mapping(uint256 => mapping(bytes32 => uint256))
		public totalContributionsInPeriod;

	/// @notice Maps periods, tags, and users to their individual contributions
	/// @dev period => tag => user address => contribution amount
	mapping(uint256 => mapping(bytes32 => mapping(address => uint256)))
		public contributionsInPeriod;

	/// @notice Maps periods and tags to their assigned weights
	/// @dev period => tag => weight
	mapping(uint256 => mapping(bytes32 => uint256)) public allWeights;

	/// @notice Stores all tags for each period
	/// @dev period => array of tags
	mapping(uint256 => bytes32[]) private allTags;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize(address admin) external initializer {
		__UUPSUpgradeable_init();
		__AccessControl_init();
		_grantRole(DEFAULT_ADMIN_ROLE, admin);
		_grantRole(WEIGHT_REGISTRAR, admin);
	}

	function incrementPeriod() external onlyRole(WEIGHT_REGISTRAR) {
		uint256 nextPeriod = currentPeriod + 1;
		currentPeriod = nextPeriod;
		emit PeriodIncremented(nextPeriod);
	}

	function registerWeights(
		uint256 periodNumber,
		bytes32[] memory tags,
		uint256[] memory weights
	) external onlyRole(WEIGHT_REGISTRAR) {
		if (tags.length != weights.length) {
			revert InvalidInputLength();
		}
		for (uint256 i = 0; i < tags.length; i++) {
			allWeights[periodNumber][tags[i]] = weights[i];
		}
		allTags[periodNumber] = tags;
		emit WeightRegistered(periodNumber, tags, weights);
	}

	function recordContribution(
		bytes32 tag,
		address user,
		uint256 amount
	) external onlyRole(CONTRIBUTOR) {
		uint256 currentPeriodCached = currentPeriod;
		totalContributionsInPeriod[currentPeriodCached][tag] += amount;
		contributionsInPeriod[currentPeriodCached][tag][user] += amount;
		emit ContributionRecorded(currentPeriodCached, tag, user, amount);
	}

	function getTags(
		uint256 periodNumber
	) external view returns (bytes32[] memory) {
		return allTags[periodNumber];
	}

	function getWeights(
		uint256 periodNumber
	) external view returns (uint256[] memory) {
		uint256 tagLength = allTags[periodNumber].length;
		uint256[] memory weights = new uint256[](tagLength);
		for (uint256 i = 0; i < tagLength; i++) {
			weights[i] = allWeights[periodNumber][allTags[periodNumber][i]];
		}
		return weights;
	}

	function getCurrentContribution(
		bytes32 tag,
		address user
	) external view returns (uint256) {
		return contributionsInPeriod[currentPeriod][tag][user];
	}

	function getContributionRate(
		uint256 periodNumber,
		address user
	) external view returns (UD60x18) {
		uint256 totalContribution = 0;
		uint256 userContribution = 0;
		for (uint256 i = 0; i < allTags[periodNumber].length; i++) {
			bytes32 tag = allTags[periodNumber][i];
			uint256 weight = allWeights[periodNumber][tag];
			totalContribution +=
				totalContributionsInPeriod[periodNumber][tag] *
				weight;
			userContribution +=
				contributionsInPeriod[periodNumber][tag][user] *
				weight;
		}
		return convert(userContribution).div(convert(totalContribution));
	}

	function _authorizeUpgrade(
		address newImplementation
	) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
