// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IMinter} from "./IMinter.sol";
import {IINTMAXToken} from "../token/mainnet/IINTMAXToken.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Minter
 * @dev Contract responsible for minting INTMAX tokens and distributing them to liquidity
 * @custom:security-contact security@intmax.io
 */
contract Minter is IMinter, OwnableUpgradeable, UUPSUpgradeable {
    /// @dev Reference to the INTMAX token contract
    IINTMAXToken public intmaxToken;

    /// @dev Address where liquidity tokens will be sent
    address public liquidity;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with required dependencies
     * @dev Sets up the contract with the INTMAX token and liquidity address
     * @param _intmaxToken Address of the INTMAX token
     * @param _liquidity Address for liquidity distribution
     * @custom:oz-upgrades-init-compat initializer
     */
    function initialize(
        address _intmaxToken,
        address _liquidity
    ) external initializer {
        if (_intmaxToken == address(0) || _liquidity == address(0)) {
            revert AddressZero();
        }

        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        intmaxToken = IINTMAXToken(_intmaxToken);
        liquidity = _liquidity;
    }

    /**
     * @notice Mints new INTMAX tokens to this contract
     * @dev Only the contract owner can call this function
     */
    function mint() external onlyOwner {
        uint256 balanceBefore = intmaxToken.balanceOf(address(this));
        intmaxToken.mint(address(this));
        uint256 balanceAfter = intmaxToken.balanceOf(address(this));
        uint256 mintedAmount = balanceAfter - balanceBefore;
        emit Minted(mintedAmount);
    }

    /**
     * @notice Transfers tokens from this contract to the liquidity address
     * @dev Only the contract owner can call this function
     * @param amount The amount of tokens to transfer
     */
    function transferToLiquidity(uint256 amount) external onlyOwner {
        intmaxToken.transfer(liquidity, amount);
        emit TransferredToLiquidity(amount);
    }

    /**
     * @notice Transfers tokens from this contract to the liquidity address
     * @dev Only the contract owner can call this function
     * @param amount The amount of tokens to transfer
     */
    function transferToken(address to, uint256 amount) external onlyOwner {
        intmaxToken.transfer(to, amount);
        emit TransferredTo(to, amount);
    }

    /**
     * @dev Function that authorizes an upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
