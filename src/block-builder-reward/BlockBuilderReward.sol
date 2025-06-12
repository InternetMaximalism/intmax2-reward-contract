// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IBlockBuilderReward} from "./IBlockBuilderReward.sol";
import {IContribution} from "@intmax2contract/contracts/contribution/IContribution.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title BlockBuilderReward
 * @notice Contract for managing and distributing rewards to block builders
 * @dev This contract calculates and distributes rewards based on users' contributions
 * to block building as recorded in the Contribution contract. It implements the UUPS
 * upgradeable pattern and uses AccessControl for role-based permissions.
 */
contract BlockBuilderReward is IBlockBuilderReward, AccessControlUpgradeable, UUPSUpgradeable {
    /// @notice Role that grants permission to set reward amounts for distribution periods
    /// @dev Accounts with this role can call the setReward function to allocate tokens for each period
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");

    /// @notice Contribution tag for identifying block posting activities
    /// @dev Used to query contribution scores from the Contribution contract
    bytes32 constant BLOCK_POST_TAG = keccak256("POST_BLOCK");

    /// @notice Reference to the Contribution contract for accessing contribution scores
    IContribution public contribution;

    /// @notice Reference to the INTMAX token contract for reward distribution
    IERC20 public intmaxToken;

    /// @notice Mapping of period numbers to their total reward information
    mapping(uint256 => TotalReward) public totalRewards;

    /// @notice Mapping to track which users have claimed rewards for which periods
    /// @dev First key is period number, second key is user address, value is whether claimed
    mapping(uint256 => mapping(address => bool)) public claimed;

    /// @notice Constructor that disables initializers to prevent implementation contract initialization
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with required dependencies
     * @dev This function can only be called once due to the initializer modifier
     * @param _admin Address that will be granted the DEFAULT_ADMIN_ROLE
     * @param _rewardManager Address that will be granted the REWARD_MANAGER_ROLE
     * @param _contribution Address of the Contribution contract for accessing contribution scores
     * @param _intmaxToken Address of the INTMAX token used for reward distribution
     * @custom:throws AddressZero if any address parameter is the zero address
     */
    function initialize(address _admin, address _rewardManager, address _contribution, address _intmaxToken)
        external
        initializer
    {
        if (
            _admin == address(0) || _rewardManager == address(0) || _contribution == address(0)
                || _intmaxToken == address(0)
        ) {
            revert AddressZero();
        }
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(REWARD_MANAGER_ROLE, _rewardManager);
        contribution = IContribution(_contribution);
        intmaxToken = IERC20(_intmaxToken);
    }

    /**
     * @notice Sets the total reward amount for a specific period
     * @dev Only callable by accounts with the REWARD_MANAGER_ROLE
     * @param periodNumber The period number for which the reward is being set
     * @param amount The total amount of tokens to distribute as rewards for the given period
     * @custom:throws RewardTooLarge if amount exceeds uint248 max value
     * @custom:throws AlreadySetReward if reward for this period has already been set
     */
    function setReward(uint256 periodNumber, uint256 amount) external onlyRole(REWARD_MANAGER_ROLE) {
        uint248 amount248 = uint248(amount);
        if (amount != uint256(amount248)) {
            revert RewardTooLarge();
        }
        TotalReward memory totalReward = totalRewards[periodNumber];
        if (totalReward.isSet) {
            revert AlreadySetReward();
        }
        totalRewards[periodNumber] = TotalReward({isSet: true, amount: amount248});
        emit SetReward(periodNumber, amount);
    }

    /**
     * @notice Retrieves the reward information for a specific period
     * @dev Returns whether a reward has been set and the reward amount for the given period
     * @param periodNumber The period number for which to retrieve reward information
     * @return A tuple containing:
     *         - A boolean indicating whether a reward has been set for the period
     *         - The total reward amount for the period (returns 0 if not set)
     */
    function getReward(uint256 periodNumber) external view returns (bool, uint256) {
        TotalReward memory totalReward = totalRewards[periodNumber];
        return (totalReward.isSet, uint256(totalReward.amount));
    }

    /**
     * @notice Retrieves the current period number from the Contribution contract
     * @dev This is a pass-through function to the Contribution contract's getCurrentPeriod function
     * @return The current period number
     */
    function getCurrentPeriod() external view returns (uint256) {
        return contribution.getCurrentPeriod();
    }

    /**
     * @notice Claims the caller's share of rewards for a specific period
     * @dev The reward amount is calculated based on the user's contribution relative to the total contributions
     * for the specified period and tag. The formula is: (totalReward * userContribution) / totalContributions
     * @param periodNumber The period number for which the reward is being claimed
     * @custom:throws PeriodNotEnded if the specified period has not yet ended
     * @custom:throws NotSetReward if no reward has been set for the specified period
     * @custom:throws AlreadyClaimed if the caller has already claimed their reward for this period
     */
    function claimReward(uint256 periodNumber) public {
        if (contribution.getCurrentPeriod() <= periodNumber) {
            revert PeriodNotEnded();
        }
        TotalReward memory _totalReward = totalRewards[periodNumber];
        if (!_totalReward.isSet) {
            revert NotSetReward();
        }
        uint256 totalReward = uint256(_totalReward.amount);
        if (claimed[periodNumber][_msgSender()]) {
            revert AlreadyClaimed();
        } else {
            claimed[periodNumber][_msgSender()] = true;
        }
        uint256 totalContributions = contribution.totalContributions(periodNumber, BLOCK_POST_TAG);
        if (totalContributions == 0) {
            revert TriedToClaimZeroReward();
        }
        uint256 reward = (totalReward * contribution.userContributions(periodNumber, BLOCK_POST_TAG, _msgSender()))
            / totalContributions;
        intmaxToken.transfer(_msgSender(), reward);
        emit Claimed(periodNumber, _msgSender(), reward);
    }

    /**
     * @notice Claims the caller's share of rewards for multiple periods in a single transaction
     * @dev Calls claimReward for each period number in the array, which performs all necessary validations
     * @param periodNumbers An array of period numbers for which rewards are being claimed
     * @custom:throws PeriodNotEnded if any specified period has not yet ended
     * @custom:throws NotSetReward if no reward has been set for any specified period
     * @custom:throws AlreadyClaimed if the caller has already claimed their reward for any period
     */
    function batchClaimReward(uint256[] calldata periodNumbers) external {
        for (uint256 i = 0; i < periodNumbers.length; i++) {
            uint256 period = periodNumbers[i];
            claimReward(period);
        }
    }

    /**
     * @notice Calculates the claimable reward amount for a specific user and period
     * @dev The reward amount is calculated based on the user's contribution relative to the total contributions
     * for the specified period and tag. Returns 0 if the period has not ended, no reward has been set,
     * or the user has already claimed their reward.
     * @param periodNumber The period number for which to calculate the claimable reward
     * @param user The address of the user for whom to calculate the claimable reward
     * @return The amount of tokens the user can claim as reward for the specified period
     */
    function getClaimableReward(uint256 periodNumber, address user) external view returns (uint256) {
        if (contribution.getCurrentPeriod() <= periodNumber) {
            return 0;
        }
        TotalReward memory _totalReward = totalRewards[periodNumber];
        if (!_totalReward.isSet) {
            return 0;
        }
        uint256 totalReward = uint256(_totalReward.amount);
        if (claimed[periodNumber][user]) {
            return 0;
        }
        uint256 totalContributions = contribution.totalContributions(periodNumber, BLOCK_POST_TAG);
        if (totalContributions == 0) {
            return 0;
        }
        return (totalReward * contribution.userContributions(periodNumber, BLOCK_POST_TAG, user)) / totalContributions;
    }

    /**
     * @notice Authorizes an upgrade to a new implementation
     * @dev Only accounts with the DEFAULT_ADMIN_ROLE can authorize upgrades
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
