// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IMinter {
    /// @notice address is zero address
    error AddressZero();

    function mint() external;

    function transferToLiquidity(uint256 amount) external;
}
