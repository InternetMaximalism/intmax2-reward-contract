// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IContribution} from "./IContribution.sol";

contract Contribution is IContribution, UUPSUpgradeable, AccessControlUpgradeable {
    /// @notice Role identifier for contracts that can record contributions
    bytes32 public constant CONTRIBUTOR = keccak256("CONTRIBUTOR");

    /// @notice start timestamp of the contribution period
    uint256 public startTimestamp;

    /// @notice period interval
    uint256 public periodInterval;

    /// @notice Maps periods and tags to total contributions
    /// @dev period => tag => total contribution amount
    mapping(uint256 => mapping(bytes32 => uint256)) public totalContributions;

    /// @notice Maps periods, tags, and users to their individual contributions
    /// @dev period => tag => user address => contribution amount
    mapping(uint256 => mapping(bytes32 => mapping(address => uint256))) public userContributions;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, uint256 _periodInterval) external initializer {
        if (_periodInterval == 0) {
            revert periodIntervalZero();
        }
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        periodInterval = _periodInterval;
        if (periodInterval > 1 days) {
            // align the start timestamp to the start of the day
            startTimestamp = (block.timestamp / 1 days) * 1 days;
        } else {
            // align the start timestamp to the start of the period
            startTimestamp = (block.timestamp / periodInterval) * periodInterval;
        }
    }

    function getCurrentPeriod() public view returns (uint256) {
        return (block.timestamp - startTimestamp) / periodInterval;
    }

    function recordContribution(bytes32 tag, address user, uint256 amount) external onlyRole(CONTRIBUTOR) {
        uint256 currentPeriodCached = getCurrentPeriod();
        totalContributions[currentPeriodCached][tag] += amount;
        userContributions[currentPeriodCached][tag][user] += amount;
        emit ContributionRecorded(currentPeriodCached, tag, user, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
