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
     * @notice Emitted when INTMAX tokens are minted
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
     * @dev Can only be called by the contract owner
     */
    function mint() external;

    /**
     * @notice Transfers tokens from this contract to the liquidity address
     * @dev Can only be called by the contract owner
     * @param amount The amount of tokens to transfer
     */
    function transferToLiquidity(uint256 amount) external;
}
