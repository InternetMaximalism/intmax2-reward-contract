// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IBlockBuilderReward} from "./IBlockBuilderReward.sol";
import {IContribution} from "../contribution/IContribution.sol";
import {IL2ScrollMessenger} from "@scroll-tech/contracts/L2/IL2ScrollMessenger.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BlockBuilderReward is
    IBlockBuilderReward,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IContribution private contribution;
    IL2ScrollMessenger private l2ScrollMessenger;
    address private minter;

    modifier onlyMinterContract() {
        IL2ScrollMessenger l2ScrollMessengerCached = l2ScrollMessenger;
        if (_msgSender() != address(l2ScrollMessengerCached)) {
            revert OnlyScrollMessenger();
        }
        if (minter != l2ScrollMessengerCached.xDomainMessageSender()) {
            revert OnlyMinter();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function deposit(uint256 amount) external onlyMinterContract {
        // deposit amount to contribution contract
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
