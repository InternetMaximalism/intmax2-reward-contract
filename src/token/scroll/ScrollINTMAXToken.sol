// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title ScrollINTMAXToken
 * @notice ERC20 token implementation for INTMAX on Scroll network
 * @dev This contract implements an ERC20 token with access control and transfer restrictions
 *      that can be lifted by an admin. It includes a DISTRIBUTOR role for privileged transfers.
 */
contract ScrollINTMAXToken is ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    /**
     * @dev Emitted when a transfer is attempted while transfers are not allowed and sender is not a distributor.
     */
    error TransferNotAllowed();

    /**
     * @notice Role identifier for distributors who can transfer tokens even when transfers are disabled
     * @dev Keccak256 hash of "DISTRIBUTOR"
     */
    bytes32 public constant DISTRIBUTOR = keccak256("DISTRIBUTOR");

    /**
     * @notice Flag indicating whether token transfers are allowed for regular users
     * @dev When false, only distributors, minting, and burning operations are permitted
     */
    bool public transfersAllowed;

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the ScrollINTMAX token contract
     * @dev Sets up initial token supply, roles, and disables transfers by default
     * @param _admin Address that will be granted the DEFAULT_ADMIN_ROLE
     * @param _rewardContract Address that will be granted the DISTRIBUTOR role
     * @param _mintAmount Initial amount of tokens to mint to the admin
     */
    function initialize(address _admin, address _rewardContract, uint256 _mintAmount) external initializer {
        transfersAllowed = false;
        __ERC20_init("ScrollINTMAX", "sITX");
        __AccessControl_init();
        _mint(_rewardContract, _mintAmount);
        _grantRole(DISTRIBUTOR, _rewardContract);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Checks if this contract supports a given interface
     * @dev Overrides AccessControl.supportsInterface to include IERC20 interface support
     * @param interfaceId The interface identifier to check
     * @return bool True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Burns a specified amount of tokens from the caller's account
     * @dev This function allows any token holder to burn their own tokens
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Enables token transfers for all users
     * @dev Once enabled, transfers cannot be disabled again
     *      Only callable by accounts with DEFAULT_ADMIN_ROLE
     */
    function allowTransfers() external onlyRole(DEFAULT_ADMIN_ROLE) {
        transfersAllowed = true;
    }

    /**
     * @dev Overrides the {ERC20-_update} function to enforce transfer restrictions
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param value The amount of tokens to transfer
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        _requireTransferAllowed(from, to);
        super._update(from, to, value);
    }

    /**
     * @dev Checks if a transfer is allowed based on current restrictions
     * @notice Internal function that enforces transfer restrictions
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @dev Allows transfers in the following cases:
     *      1. When transfers are globally enabled
     *      2. When the sender has the DISTRIBUTOR role
     *      3. For minting operations (from = address(0))
     *      4. For burning operations (to = address(0))
     *      Otherwise reverts with TransferNotAllowed
     */
    function _requireTransferAllowed(address from, address to) private view {
        if (transfersAllowed) {
            return;
        }
        // Allow transfers if the caller is a distributor
        if (hasRole(DISTRIBUTOR, from)) {
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

    /**
     * @dev Authorizes an upgrade to a new implementation
     * @param newImplementation The address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
