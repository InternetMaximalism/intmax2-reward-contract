// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IMinter} from "./IMinter.sol";
import {IINTMAXToken} from "../token/IINTMAXToken.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Minter is IMinter, OwnableUpgradeable, UUPSUpgradeable {
    IINTMAXToken private intmaxToken;

    address private liquidity;
    address private blockBuilderReward;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with required dependencies
     * @param _intmaxToken Address of the INTMAX token
     * @param _liquidity Address for liquidity distribution
     * @param _blockBuilderReward Address of the BlockBuilderReward contract
     */
    function initialize(
        address _intmaxToken,
        address _liquidity,
        address _blockBuilderReward
    ) external initializer {
        if (
            _intmaxToken == address(0) ||
            _liquidity == address(0) ||
            _blockBuilderReward == address(0)
        ) {
            revert AddressZero();
        }

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        intmaxToken = IINTMAXToken(_intmaxToken);
        liquidity = _liquidity;
        blockBuilderReward = _blockBuilderReward;
    }

    function mint() external onlyOwner {
        intmaxToken.mint(address(this));
    }

    function transferToLiquidity(uint256 amount) external onlyOwner {
        intmaxToken.transfer(liquidity, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
