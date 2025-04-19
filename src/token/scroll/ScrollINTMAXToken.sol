// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title INTMAXToken
 */
contract ScrollINTMAXToken is ERC20, AccessControl {
    /**
     * @dev Emitted when tried to transfer tokens while transfers are not allowed.
     */
    error TransferNotAllowed();

    bytes32 public constant DISTRIBUTOR = keccak256("DISTRIBUTOR");

    /**
     * @notice Whether transfers are allowed.
     */
    bool public transfersAllowed;

    constructor(
        address admin_,
        address rewardContract,
        uint256 mintAmount
    ) ERC20("ScrollINTMAX", "sITX") {
        transfersAllowed = false;
        _mint(admin_, mintAmount);
        _grantRole(DISTRIBUTOR, rewardContract);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Burns a specified amount of tokens from the caller's account.
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @notice Allows transfers.
     */
    function allowTransfers() external onlyRole(DEFAULT_ADMIN_ROLE) {
        transfersAllowed = true;
    }

    /**
     * @dev Overrides the {ERC20-_update} function to allow transfers only when transfers are allowed.
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        _requireTransferAllowed(from, to);
        super._update(from, to, value);
    }

    /**
     * @notice Reverts if transfers are not allowed.
     * @dev The function reverts if transfers are not allowed and the caller is not a distributor.
     * @param from from address
     * @param to to address
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
}
