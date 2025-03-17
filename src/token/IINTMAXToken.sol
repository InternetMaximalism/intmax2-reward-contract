// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IINTMAXToken
 * @dev Interface for the INTMAXToken contract, extending the IERC20 interface.
 */
interface IINTMAXToken is IERC20 {
    /**
     * @dev Emitted when tried to transfer tokens while transfers are not allowed.
     */
    error TransferNotAllowed();

    /**
     * @notice Returns the duration of phase 0 in days.
     * @return The duration of phase 0 in days.
     */
    // solhint-disable-next-line func-name-mixedcase
    function PHASE0_PERIOD() external view returns (uint256);

    /**
     * @notice Returns the total number of phases.
     * @return The total number of phases.
     */
    // solhint-disable-next-line func-name-mixedcase
    function NUM_PHASES() external view returns (uint256);

    /**
     * @notice Returns the role identifier for the minter
     * @return The role identifier for the minter
     */
    // solhint-disable-next-line func-name-mixedcase
    function MINTER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the token genesis timestamp.
     * @return The token genesis timestamp.
     */
    // solhint-disable-next-line func-name-mixedcase
    function GENESIS_TIMESTAMP() external view returns (uint256);

    /**
     * @notice Returns the reward per day during phase 0, in tokens (with 18 decimals).
     * @return The reward per day during phase 0, in tokens (with 18 decimals).
     */
    // solhint-disable-next-line func-name-mixedcase
    function PHASE0_REWARD_PER_DAY() external view returns (uint256);

    /**
     * @notice Returns maximum supply.
     * @return Maximum supply.
     */
    // solhint-disable-next-line func-name-mixedcase
    function MAX_SUPPLY() external view returns (uint256);

    /**
     * @notice Returns the total amount of tokens that have been burned.
     * @return The total amount of tokens that have been burned.
     */
    function totalBurnedAmount() external view returns (uint256);

    /**
     * @notice Returns the total amount of tokens that have been claimed
     * @return The total amount of tokens that have been claimed.
     */
    function totalClaimedAmount() external view returns (uint256);

    /**
     * @notice Returns whether transfers are allowed.
     * @return Whether transfers are allowed.
     */
    function transfersAllowed() external view returns (bool);

    /**
     * @notice Mints tokens to a specified address.
     * @dev Only callable by an address with the minter role.
     * @param to The address to receive the minted tokens.
     */
    function mint(address to) external;

    /**
     * @notice Burns a specified amount of tokens from the caller's account.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Enables token transfers.
     * @dev Only callable by an address with the admin role.
     */
    function allowTransfers() external;

    /**
     * @notice Returns the total amount of tokens that can be minted.
     * @return The total amount of tokens that can be minted.
     */
    function totalMintableAmount() external view returns (uint256);
}
