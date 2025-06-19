// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/**
 * @title IMinter
 * @dev Interface for the Minter contract that handles INTMAX token minting and distribution
 */
interface IMinter {
    /**
     * @dev Thrown when an address parameter is the zero address
     */
    error AddressZero();

    /**
     * @dev Thrown when mint operation fails due to balance decrease
     */
    error MintFailed();

    /**
     * @dev Thrown when no tokens were minted
     */
    error NoTokensMinted();

    /**
     * @dev Thrown when transfer amount is zero
     */
    error ZeroAmount();

    /**
     * @dev Thrown when transfer recipient is zero address
     */
    error ZeroRecipient();

    /**
     * @dev Thrown when transfer fails
     */
    error TransferFailed();

    /**
     * @dev Thrown when insufficient balance for transfer
     */
    error InsufficientBalance();

    /**
     * @notice Emitted when INTMAX tokens are minted
     * @param amount The amount of tokens minted
     */
    event Minted(uint256 amount);

    /**
     * @notice Emitted when tokens are transferred to the liquidity address
     * @param amount The amount of tokens transferred
     */
    event TransferredToLiquidity(uint256 amount);

    /**
     * @notice Emitted when tokens are transferred to a specific address
     * @param to The address receiving the tokens
     * @param amount The amount of tokens transferred
     */
    event TransferredTo(address to, uint256 amount);

    /**
     * @notice Mints new INTMAX tokens to this contract
     * @dev Can only be called by addresses with TOKEN_MANAGER_ROLE
     */
    function mint() external;

    /**
     * @notice Transfers tokens from this contract to the liquidity address
     * @dev Can only be called by addresses with TOKEN_MANAGER_ROLE
     * @param amount The amount of tokens to transfer
     */
    function transferToLiquidity(uint256 amount) external;

    /**
     * @notice Transfers tokens from this contract to the specified address
     * @dev Can only be called by addresses with DEFAULT_ADMIN_ROLE
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function transferTo(address to, uint256 amount) external;
}
