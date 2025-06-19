// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IMinter} from "./IMinter.sol";
import {IINTMAXToken} from "../token/mainnet/IINTMAXToken.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Minter
 * @notice Contract responsible for minting INTMAX tokens and distributing them to liquidity
 * @dev This contract uses role-based access control with TOKEN_MANAGER_ROLE for minting/distribution
 *      and DEFAULT_ADMIN_ROLE for administrative functions. It implements UUPS upgradeability.
 * @custom:security-contact security@intmax.io
 */
contract Minter is IMinter, AccessControlUpgradeable, UUPSUpgradeable {
    /// @notice Role that grants permission to mint tokens and transfer to liquidity
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    /// @notice Reference to the INTMAX token contract
    IINTMAXToken public intmaxToken;

    /// @notice Address where liquidity tokens will be sent
    address public liquidity;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with required dependencies
     * @dev Sets up the contract with the INTMAX token, liquidity address, and admin
     * @param _intmaxToken Address of the INTMAX token
     * @param _liquidity Address for liquidity distribution
     * @param _admin Address that will be granted the DEFAULT_ADMIN_ROLE
     * @custom:oz-upgrades-init-compat initializer
     */
    function initialize(address _intmaxToken, address _liquidity, address _admin) external initializer {
        if (_intmaxToken == address(0) || _liquidity == address(0) || _admin == address(0)) {
            revert AddressZero();
        }

        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        intmaxToken = IINTMAXToken(_intmaxToken);
        liquidity = _liquidity;
    }

    /**
     * @notice Mints new INTMAX tokens to this contract
     * @dev Only addresses with TOKEN_MANAGER_ROLE can call this function
     */
    function mint() external onlyRole(TOKEN_MANAGER_ROLE) {
        uint256 balanceBefore = intmaxToken.balanceOf(address(this));

        // Perform external call
        intmaxToken.mint(address(this));

        uint256 balanceAfter = intmaxToken.balanceOf(address(this));

        // Check for potential overflow/underflow and ensure balance increased
        if (balanceAfter < balanceBefore) {
            revert MintFailed();
        }

        uint256 mintedAmount = balanceAfter - balanceBefore;

        // Ensure tokens were actually minted
        if (mintedAmount == 0) {
            revert NoTokensMinted();
        }

        emit Minted(mintedAmount);
    }

    /**
     * @notice Transfers tokens from this contract to the liquidity address
     * @dev Only addresses with TOKEN_MANAGER_ROLE can call this function
     * @param amount The amount of tokens to transfer
     */
    function transferToLiquidity(uint256 amount) external onlyRole(TOKEN_MANAGER_ROLE) {
        if (amount == 0) {
            revert ZeroAmount();
        }

        uint256 contractBalance = intmaxToken.balanceOf(address(this));
        if (contractBalance < amount) {
            revert InsufficientBalance();
        }

        bool success = intmaxToken.transfer(liquidity, amount);
        if (!success) {
            revert TransferFailed();
        }

        emit TransferredToLiquidity(amount);
    }

    /**
     * @notice Transfers tokens from this contract to the specified address
     * @dev Only addresses with DEFAULT_ADMIN_ROLE can call this function
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     */
    function transferTo(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) {
            revert ZeroRecipient();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }

        uint256 contractBalance = intmaxToken.balanceOf(address(this));
        if (contractBalance < amount) {
            revert InsufficientBalance();
        }

        bool success = intmaxToken.transfer(to, amount);
        if (!success) {
            revert TransferFailed();
        }

        emit TransferredTo(to, amount);
    }

    /**
     * @notice Authorizes an upgrade to a new implementation
     * @dev Only addresses with DEFAULT_ADMIN_ROLE can authorize upgrades
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
