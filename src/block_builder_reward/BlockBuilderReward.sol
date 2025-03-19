// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IBlockBuilderReward} from "./IBlockBuilderReward.sol";
import {IContribution} from "../contribution/IContribution.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BlockBuilderReward is
    IBlockBuilderReward,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @notice contribution tag for block post
    bytes32 constant BLOCK_POST_TAG = keccak256("POST_BLOCK");

    IContribution private contribution;
    IERC20 private intmaxToken;
    address private minter;

    mapping(uint256 => uint256) public totalRewards;
    mapping(uint256 => bool) public claimAllowed;
    mapping(uint256 => mapping(address => bool)) public claimed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with required dependencies
     * @param _contribution Address of the Contribution contract
     * @param _intmaxToken Address of the INTMAX token
     * @param _minter Address of the Minter contract
     */
    function initialize(
        address _contribution,
        address _intmaxToken,
        address _minter
    ) external initializer {
        if (
            _contribution == address(0) ||
            _intmaxToken == address(0) ||
            _minter == address(0)
        ) {
            revert AddressZero();
        }
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        contribution = IContribution(_contribution);
        intmaxToken = IERC20(_intmaxToken);
        minter = _minter;
    }

    function setReward(uint256 periodNumber, uint256 amount) external {
        if (claimAllowed[periodNumber]) {
            revert ClaimAllowed();
        }
        totalRewards[periodNumber] = amount;
        emit SetReward(periodNumber, amount);
    }

    function allowClaim(uint256 periodNumber) external {
        if (contribution.getCurrentPeriod() <= periodNumber) {
            revert PeriodNotEnded();
        }
        if (claimAllowed[periodNumber]) {
            revert ClaimAllowed();
        }
        claimAllowed[periodNumber] = true;
    }

    function claimReward(uint256 periodNumber) external {
        if (!claimAllowed[periodNumber]) {
            revert ClaimNotAllowed();
        }
        if (claimed[periodNumber][_msgSender()]) {
            revert AlreadyClaimed();
        } else {
            claimed[periodNumber][_msgSender()] = true;
        }
        uint reward = (totalRewards[periodNumber] *
            contribution.userContributions(
                periodNumber,
                BLOCK_POST_TAG,
                _msgSender()
            )) / contribution.totalContributions(periodNumber, BLOCK_POST_TAG);
        intmaxToken.transfer(_msgSender(), reward);
        emit Claimed(periodNumber, _msgSender(), reward);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
