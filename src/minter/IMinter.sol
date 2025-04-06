// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IMinter {
    /// @notice address is zero address
    error AddressZero();

    /// @notice mint to this contract
    function mint() external;

    /// @notice transfer to liquidity
    function transferToLiquidity(uint256 amount) external;
}
