// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {BlockBuilderReward} from "../../src/block-builder-reward/BlockBuilderReward.sol";
import {IBlockBuilderReward} from "../../src/block-builder-reward/IBlockBuilderReward.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract testIntMaxToken is ERC20 {
    constructor() ERC20("TestIntMaxToken", "TIMT") {}

    function mint(address to) external {
        _mint(to, 1000);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}

contract BlockBuilderReward2 is BlockBuilderReward {}

contract TestContribution {
    uint256 public currentPeriod;
    mapping(uint256 => mapping(bytes32 => uint256)) public totalContributions;
    mapping(uint256 => mapping(bytes32 => mapping(address => uint256))) public userContributions;

    function getCurrentPeriod() public view returns (uint256) {
        return currentPeriod;
    }

    function setCurrentPeriod(uint256 period) external {
        currentPeriod = period;
    }

    function setUserContribution(uint256 period, bytes32 tag, address user, uint256 amount) external {
        userContributions[period][tag][user] = amount;
    }

    function setTotalContribution(uint256 period, bytes32 tag, uint256 amount) external {
        totalContributions[period][tag] = amount;
    }
}

contract BlockBuilderRewardTest is Test {
    BlockBuilderReward public builder;
    testIntMaxToken public token;
    TestContribution public contribution;
    address private nonOwner = address(0x99);
    address private user1 = address(0x1);

    function setUp() public {
        token = new testIntMaxToken();
        contribution = new TestContribution();
        BlockBuilderReward implementation = new BlockBuilderReward();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(BlockBuilderReward.initialize.selector, address(contribution), address(token))
        );

        builder = BlockBuilderReward(address(proxy));
        vm.prank(address(this));
        builder.transferOwnership(address(this));
        token.mint(address(builder));
    }

    function test_initializeOwnerAddressSet() public view {
        address owner = builder.owner();
        assertEq(owner, address(this));
    }

    function test_initializeZeroAddress1() public {
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.expectRevert(IBlockBuilderReward.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(BlockBuilderReward.initialize.selector, address(0), address(1))
        );
    }

    function test_initializeZeroAddress2() public {
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.expectRevert(IBlockBuilderReward.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(BlockBuilderReward.initialize.selector, address(1), address(0))
        );
    }

    function test_setReward() public {
        (bool isSet, uint248 amount) = builder.totalRewards(1);
        assertEq(isSet, false);
        builder.setReward(1, 1000);
        (isSet, amount) = builder.totalRewards(1);
        assertEq(amount, 1000);
        assertEq(isSet, true);
    }

    function test_emitSetReward() public {
        vm.expectEmit(true, true, true, true);
        emit IBlockBuilderReward.SetReward(1, 1000);
        builder.setReward(1, 1000);
    }

    function test_nonOwnerSetReward() public {
        vm.prank(nonOwner);
        bytes memory expectedRevert =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner);
        vm.expectRevert(expectedRevert);
        builder.setReward(1, 1000);
    }

    function test_setRewardAlreadySet() public {
        builder.setReward(1, 1000);
        vm.expectRevert(IBlockBuilderReward.AlreadySetReward.selector);
        builder.setReward(1, 2000);
    }

    function test_setRewardTooLarge() public {
        uint256 tooLargeAmount = uint256(type(uint248).max) + 1;
        vm.expectRevert(IBlockBuilderReward.RewardTooLarge.selector);
        builder.setReward(1, tooLargeAmount);
    }

    function test_claimReward() public {
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        vm.prank(user1);
        builder.claimReward(1);

        assertEq(token.balanceOf(user1), 500);
    }

    function test_emitClaimed() public {
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        vm.expectEmit(true, true, true, true);
        emit IBlockBuilderReward.Claimed(1, user1, 500);
        vm.prank(user1);
        builder.claimReward(1);
    }

    function test_PeriodNotEnded() public {
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(1);
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.PeriodNotEnded.selector);
        builder.claimReward(1);
    }

    function test_claimNotSetReward() public {
        contribution.setCurrentPeriod(2);
        vm.prank(user1);
        bytes memory expectedRevert = abi.encodeWithSelector(IBlockBuilderReward.NotSetReward.selector, 1);
        vm.expectRevert(expectedRevert);
        builder.claimReward(1);
    }

    function test_alreadyClaimed() public {
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);
        vm.prank(user1);
        builder.claimReward(1);
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.AlreadyClaimed.selector);
        builder.claimReward(1);
    }

    function test_unauthorizedUpgrade() public {
        vm.prank(nonOwner);
        bytes memory expectedRevert =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner);
        vm.expectRevert(expectedRevert);
        builder.upgradeToAndCall(address(0x3), "");
    }

    function test_authorizedUpgrade() public {
        BlockBuilderReward2 newImplementation = new BlockBuilderReward2();
        vm.prank(address(this));
        builder.upgradeToAndCall(address(newImplementation), "");
    }
}
