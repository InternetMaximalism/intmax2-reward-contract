// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IBlockBuilderReward} from "./IBlockBuilderReward.sol";
import {IContribution} from "../contribution/IContribution.sol";
import {IL2ScrollMessenger} from "@scroll-tech/contracts/L2/IL2ScrollMessenger.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UD60x18, convert} from "@prb/math/src/UD60x18.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BlockBuilderReward is
    IBlockBuilderReward,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IContribution private contribution;
    IL2ScrollMessenger private l2ScrollMessenger;
    IERC20 private intmaxToken;
    address private minter;

    mapping(uint256 => uint256) private periodToTotalReward;
    mapping(uint256 => mapping(address => bool)) public claimed;

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

    /**
     * @notice Initializes the contract with required dependencies
     * @param _contribution Address of the Contribution contract
     * @param _l2ScrollMessenger Address of the L2ScrollMessenger contract
     * @param _intmaxToken Address of the INTMAX token
     * @param _minter Address of the Minter contract
     */
    function initialize(
        address _contribution,
        address _l2ScrollMessenger,
        address _intmaxToken,
        address _minter
    ) external initializer {
        if (_contribution == address(0) || 
            _l2ScrollMessenger == address(0) || 
            _intmaxToken == address(0) || 
            _minter == address(0)) {
            revert AddressZero();
        }
        
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        contribution = IContribution(_contribution);
        l2ScrollMessenger = IL2ScrollMessenger(_l2ScrollMessenger);
        intmaxToken = IERC20(_intmaxToken);
        minter = _minter;
    }

    function deposit(
        uint256 periodNumber,
        uint256 amount
    ) external onlyMinterContract {
        periodToTotalReward[periodNumber] += amount;
        emit Deposited(periodNumber, amount);
    }

    function claimReward(uint256 periodNumber) external {
        if (contribution.currentPeriod() <= periodNumber) {
            revert PeriodNotEnded();
        }
        if (claimed[periodNumber][_msgSender()]) {
            revert AlreadyClaimed();
        } else {
            claimed[periodNumber][_msgSender()] = true;
        }
        UD60x18 contributionRate = contribution.getContributionRate(
            periodNumber,
            _msgSender()
        );
        uint256 reward = (convert(periodToTotalReward[periodNumber]) *
            contributionRate).unwrap();
        intmaxToken.transfer(_msgSender(), reward);
        emit Claimed(periodNumber, _msgSender(), reward);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
