// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IINTMAXToken} from "./IINTMAXToken.sol";

/**
 * @title INTMAXToken
 */
contract INTMAXToken is ERC20, AccessControl, IINTMAXToken {
    /**
     * @notice The duration of phase 0 in days.
     */
    uint256 public constant PHASE0_PERIOD = 16;

    /**
     * @notice The total number of phases.
     * @dev From phase0 to phase6.
     */
    uint256 public constant NUM_PHASES = 7;

    /**
     * @notice The role identifier for the minter.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice The token genesis timestamp.
     */
    uint256 public constant GENESIS_TIMESTAMP = 1722999120;

    /**
     * @notice The reward per day during phase 0, in tokens (with 18 decimals).
     */
    uint256 public immutable PHASE0_REWARD_PER_DAY;

    /**
     * @notice Maximum supply.
     */
    uint256 public immutable MAX_SUPPLY;

    /**
     * @notice The total amount of tokens that have been burned.
     */
    uint256 public totalBurnedAmount;

    /**
     * @notice The total amount of tokens that have been claimed through minting.
     */
    uint256 public totalClaimedAmount;

    /**
     * @notice Whether transfers are allowed.
     */
    bool public transfersAllowed;

    /**
     * @dev Sets the token name and symbol, and initializes the owner and minter.
     * @param admin_ The address of the initial admin.
     * @param minter_ The address of the initial minter.
     */
    constructor(address admin_, address minter_) ERC20("INTMAX", "ITX") {
        // The reward per day is 8937500 tokens.
        PHASE0_REWARD_PER_DAY = 8937500 * (10 ** decimals());
        MAX_SUPPLY = PHASE0_REWARD_PER_DAY * PHASE0_PERIOD * NUM_PHASES;
        transfersAllowed = false;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(MINTER_ROLE, minter_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IINTMAXToken).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Mints tokens to a specified address.
     * @dev Only callable by the minter.
     * @param to The address to mint tokens to.
     */
    function mint(address to) external onlyRole(MINTER_ROLE) {
        uint256 mintable = totalMintableAmount();
        _mint(to, mintable - totalClaimedAmount);
        totalClaimedAmount = mintable;
    }

    /**
     * @notice Burns a specified amount of tokens from the caller's account.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        totalBurnedAmount += amount;
    }

    /**
     * @notice Allows transfers.
     */
    function allowTransfers() external onlyRole(DEFAULT_ADMIN_ROLE) {
        transfersAllowed = true;
    }

    /**
     * @notice Calculates the total mintable amount up to the current date.
     * @dev The total mintable amount follows a specific issuance curve:
     * - There are phases from phase0 to phase6.
     * - Phase0 starts at the moment the contract is deployed.
     * - The duration of phase I is 2^I times the duration of phase0.
     * - The amount that can be minted per day in phase I is 1/2^I of the amount that can be minted per day in phase0.
     * - Therefore, the total amount that can be minted in each phase is constant.
     * - Additionally, half of the burned amount can be minted.
     * - After phase6 ends, no more minting is allowed.
     * - The function iterates through each phase, doubling the duration and halving the daily reward,
     *   accumulating the total mintable amount until the current date.
     * @return The total mintable amount up to the current date.
     */
    function totalMintableAmount() public view returns (uint256) {
        uint256 elapsedDays = (block.timestamp - GENESIS_TIMESTAMP) / 1 days;
        uint256 totalReward = 0;
        uint256 rewardPerDay = PHASE0_REWARD_PER_DAY;

        for (uint256 i = 0; i < NUM_PHASES; i++) {
            uint256 phaseDays = PHASE0_PERIOD << i;
            if (elapsedDays < phaseDays) {
                totalReward += elapsedDays * rewardPerDay;
                break;
            }
            totalReward += phaseDays * rewardPerDay;
            elapsedDays -= phaseDays;
            rewardPerDay >>= 1;
        }

        // Add half of the total burned amount to the total reward
        return totalReward + (totalBurnedAmount / 2);
    }

    /**
     * @dev Overrides the {ERC20-_update} function to allow transfers only when transfers are allowed.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        _requireTransferAllowed(from, to);
        super._update(from, to, value);
    }

    /**
     * @notice Reverts if transfers are not allowed.
     * @dev The function reverts if transfers are not allowed and the caller is not a minter.
     * @param from from address
     * @param to to address
     */
    function _requireTransferAllowed(address from, address to) private view {
        if (transfersAllowed) {
            return;
        }
        // Minter can transfer tokens
        if (hasRole(MINTER_ROLE, from)) {
            return;
        }
        // Minting is always allowed
        if (from == address(0)) {
            return;
        }
        // Burning is always allowed
        if (to == address(0)) {
            return;
        }
        revert TransferNotAllowed();
    }
}
