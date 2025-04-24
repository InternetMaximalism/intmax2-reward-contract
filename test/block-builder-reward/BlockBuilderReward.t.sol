// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {BlockBuilderReward} from "../../src/block-builder-reward/BlockBuilderReward.sol";
import {IBlockBuilderReward} from "../../src/block-builder-reward/IBlockBuilderReward.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract testIntMaxToken is ERC20 {
    constructor() ERC20("TestIntMaxToken", "TIMT") {}

    function mint(address to) external {
        _mint(to, 10000);
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
    address private admin = address(this);
    address private rewardManager = address(0x88);
    address private nonAdmin = address(0x99);
    address private user1 = address(0x1);

    function setUp() public {
        token = new testIntMaxToken();
        contribution = new TestContribution();
        BlockBuilderReward implementation = new BlockBuilderReward();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                BlockBuilderReward.initialize.selector, admin, rewardManager, address(contribution), address(token)
            )
        );

        builder = BlockBuilderReward(address(proxy));
        token.mint(address(builder));
    }

    function test_initializeRolesSet() public view {
        assertTrue(builder.hasRole(builder.DEFAULT_ADMIN_ROLE(), admin), "Admin role not set correctly");
        assertTrue(
            builder.hasRole(builder.REWARD_MANAGER_ROLE(), rewardManager), "Reward manager role not set correctly"
        );
    }

    function test_initializeZeroAddress1() public {
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.expectRevert(IBlockBuilderReward.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                BlockBuilderReward.initialize.selector, address(0), rewardManager, address(contribution), address(token)
            )
        );
    }

    function test_initializeZeroAddress2() public {
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.expectRevert(IBlockBuilderReward.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                BlockBuilderReward.initialize.selector, admin, address(0), address(contribution), address(token)
            )
        );
    }

    function test_initializeZeroAddress3() public {
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.expectRevert(IBlockBuilderReward.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                BlockBuilderReward.initialize.selector, admin, rewardManager, address(0), address(token)
            )
        );
    }

    function test_initializeZeroAddress4() public {
        BlockBuilderReward implementation = new BlockBuilderReward();
        vm.expectRevert(IBlockBuilderReward.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                BlockBuilderReward.initialize.selector, admin, rewardManager, address(contribution), address(0)
            )
        );
    }

    function test_setReward() public {
        (bool isSet, uint248 amount) = builder.totalRewards(1);
        assertEq(isSet, false);
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        (isSet, amount) = builder.totalRewards(1);
        assertEq(amount, 1000);
        assertEq(isSet, true);
    }

    function test_emitSetReward() public {
        vm.expectEmit(true, true, true, true);
        emit IBlockBuilderReward.SetReward(1, 1000);
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
    }

    function test_nonRewardManagerSetReward() public {
        vm.prank(nonAdmin);
        vm.expectRevert();
        builder.setReward(1, 1000);
    }

    function test_setRewardAlreadySet() public {
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        vm.prank(rewardManager);
        vm.expectRevert(IBlockBuilderReward.AlreadySetReward.selector);
        builder.setReward(1, 2000);
    }

    function test_setRewardTooLarge() public {
        uint256 tooLargeAmount = uint256(type(uint248).max) + 1;
        vm.prank(rewardManager);
        vm.expectRevert(IBlockBuilderReward.RewardTooLarge.selector);
        builder.setReward(1, tooLargeAmount);
    }

    function test_claimReward() public {
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        vm.prank(user1);
        builder.claimReward(1);

        assertEq(token.balanceOf(user1), 500);
    }

    function test_emitClaimed() public {
        vm.prank(rewardManager);
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
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(1);
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.PeriodNotEnded.selector);
        builder.claimReward(1);
    }

    function test_claimNotSetReward() public {
        contribution.setCurrentPeriod(2);
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.NotSetReward.selector);
        builder.claimReward(1);
    }

    function test_alreadyClaimed() public {
        vm.prank(rewardManager);
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
        vm.prank(nonAdmin);
        vm.expectRevert();
        builder.upgradeToAndCall(address(0x3), "");
    }

    function test_authorizedUpgrade() public {
        BlockBuilderReward2 newImplementation = new BlockBuilderReward2();
        vm.prank(admin);
        builder.upgradeToAndCall(address(newImplementation), "");
    }

    function test_getClaimableReward_periodNotEnded() public {
        // Set up the test
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(1); // Period 1 has not ended
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Check that getClaimableReward returns 0 when period has not ended
        uint256 claimableReward = builder.getClaimableReward(1, user1);
        assertEq(claimableReward, 0, "Should return 0 when period has not ended");
    }

    function test_getClaimableReward_rewardNotSet() public {
        // Set up the test
        contribution.setCurrentPeriod(2); // Period 1 has ended
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Check that getClaimableReward returns 0 when reward is not set
        uint256 claimableReward = builder.getClaimableReward(1, user1);
        assertEq(claimableReward, 0, "Should return 0 when reward is not set");
    }

    function test_getClaimableReward_alreadyClaimed() public {
        // Set up the test
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2); // Period 1 has ended
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Claim the reward first
        vm.prank(user1);
        builder.claimReward(1);

        // Check that getClaimableReward returns 0 when already claimed
        uint256 claimableReward = builder.getClaimableReward(1, user1);
        assertEq(claimableReward, 0, "Should return 0 when already claimed");
    }

    function test_getClaimableReward_correctCalculation() public {
        // Set up the test
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2); // Period 1 has ended
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Check that getClaimableReward returns the correct amount
        uint256 claimableReward = builder.getClaimableReward(1, user1);
        assertEq(claimableReward, 500, "Should return correct reward amount (1000 * 50 / 100 = 500)");
    }

    function test_getClaimableReward_zeroContribution() public {
        // Set up the test
        vm.prank(rewardManager);
        builder.setReward(1, 1000);
        contribution.setCurrentPeriod(2); // Period 1 has ended
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 0);

        // Check that getClaimableReward returns 0 when user has no contribution
        uint256 claimableReward = builder.getClaimableReward(1, user1);
        assertEq(claimableReward, 0, "Should return 0 when user has no contribution");
    }

    function test_blockbuilderreward_getReward_notSet() public view {
        // When reward is not set for a period
        (bool isSet, uint256 amount) = builder.getReward(1);

        // Should return (false, 0)
        assertEq(isSet, false, "isSet should be false when reward is not set");
        assertEq(amount, 0, "amount should be 0 when reward is not set");
    }

    function test_blockbuilderreward_getReward_isSet() public {
        // Set a reward for period 1
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        // When reward is set for a period
        (bool isSet, uint256 amount) = builder.getReward(1);

        // Should return (true, rewardAmount)
        assertEq(isSet, true, "isSet should be true when reward is set");
        assertEq(amount, 1000, "amount should match the set reward amount");
    }

    function test_blockbuilderreward_batchClaimReward() public {
        // Set rewards for multiple periods
        vm.startPrank(rewardManager);
        builder.setReward(1, 1000);
        builder.setReward(2, 2000);
        vm.stopPrank();

        // Set up contribution data
        contribution.setCurrentPeriod(3); // Periods 1 and 2 have ended

        // Set contributions for period 1
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Set contributions for period 2
        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 200);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 100);

        // Initial balance should be 0
        assertEq(token.balanceOf(user1), 0);

        // Batch claim rewards for periods 1 and 2
        uint256[] memory periodNumbers = new uint256[](2);
        periodNumbers[0] = 1;
        periodNumbers[1] = 2;

        vm.prank(user1);
        builder.batchClaimReward(periodNumbers);

        // Expected rewards:
        // Period 1: 1000 * 50 / 100 = 500
        // Period 2: 2000 * 100 / 200 = 1000
        // Total: 500 + 1000 = 1500
        assertEq(token.balanceOf(user1), 1500, "Should receive correct total reward amount");

        // Verify that rewards are marked as claimed
        assertTrue(builder.claimed(1, user1), "Period 1 should be marked as claimed");
        assertTrue(builder.claimed(2, user1), "Period 2 should be marked as claimed");
    }

    function test_blockbuilderreward_batchClaimReward_emitEvents() public {
        // Set rewards for multiple periods
        vm.startPrank(rewardManager);
        builder.setReward(1, 1000);
        builder.setReward(2, 2000);
        vm.stopPrank();

        // Set up contribution data
        contribution.setCurrentPeriod(3); // Periods 1 and 2 have ended

        // Set contributions for period 1
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Set contributions for period 2
        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 200);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 100);

        // Prepare period numbers array
        uint256[] memory periodNumbers = new uint256[](2);
        periodNumbers[0] = 1;
        periodNumbers[1] = 2;

        // Expect Claimed events for both periods
        vm.expectEmit(true, true, true, true);
        emit IBlockBuilderReward.Claimed(1, user1, 500);

        vm.expectEmit(true, true, true, true);
        emit IBlockBuilderReward.Claimed(2, user1, 1000);

        // Batch claim rewards
        vm.prank(user1);
        builder.batchClaimReward(periodNumbers);
    }

    function test_blockbuilderreward_batchClaimReward_periodNotEnded() public {
        // Set rewards for periods 1 and 2
        vm.startPrank(rewardManager);
        builder.setReward(1, 1000);
        builder.setReward(2, 2000);
        vm.stopPrank();

        // Set current period to 2, so period 2 has not ended yet
        contribution.setCurrentPeriod(2);

        // Set contributions
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);
        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 200);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 100);

        // Prepare period numbers array with a period that hasn't ended
        uint256[] memory periodNumbers = new uint256[](2);
        periodNumbers[0] = 1; // This period has ended
        periodNumbers[1] = 2; // This period has NOT ended

        // Expect revert when trying to claim for period 2
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.PeriodNotEnded.selector);
        builder.batchClaimReward(periodNumbers);
    }

    function test_blockbuilderreward_batchClaimReward_notSetReward() public {
        // Set reward only for period 1
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        // Set current period to 3, so both periods have ended
        contribution.setCurrentPeriod(3);

        // Set contributions
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);
        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 200);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 100);

        // Prepare period numbers array with a period that has no reward set
        uint256[] memory periodNumbers = new uint256[](2);
        periodNumbers[0] = 1; // Reward is set for this period
        periodNumbers[1] = 2; // Reward is NOT set for this period

        // Expect revert when trying to claim for period 2
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.NotSetReward.selector);
        builder.batchClaimReward(periodNumbers);
    }

    function test_blockbuilderreward_batchClaimReward_alreadyClaimed() public {
        // Set rewards for periods 1 and 2
        vm.startPrank(rewardManager);
        builder.setReward(1, 1000);
        builder.setReward(2, 2000);
        vm.stopPrank();

        // Set current period to 3, so both periods have ended
        contribution.setCurrentPeriod(3);

        // Set contributions
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);
        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 200);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 100);

        // Claim reward for period 1 first
        vm.prank(user1);
        builder.claimReward(1);

        // Prepare period numbers array including the already claimed period
        uint256[] memory periodNumbers = new uint256[](2);
        periodNumbers[0] = 1; // Already claimed
        periodNumbers[1] = 2; // Not claimed yet

        // Expect revert when trying to batch claim with an already claimed period
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.AlreadyClaimed.selector);
        builder.batchClaimReward(periodNumbers);
    }

    function test_blockbuilderreward_batchClaimReward_emptyArray() public {
        // Prepare empty period numbers array
        uint256[] memory periodNumbers = new uint256[](0);

        // Should execute without errors (loop won't run)
        vm.prank(user1);
        builder.batchClaimReward(periodNumbers);

        // Balance should remain unchanged
        assertEq(token.balanceOf(user1), 0);
    }

    function test_blockbuilderreward_getCurrentPeriod() public {
        // Set a specific period in the contribution contract
        uint256 expectedPeriod = 42;
        contribution.setCurrentPeriod(expectedPeriod);

        // Call getCurrentPeriod and verify it returns the correct value
        uint256 actualPeriod = builder.getCurrentPeriod();

        // Assert that the returned period matches the expected period
        assertEq(
            actualPeriod,
            expectedPeriod,
            "getCurrentPeriod should return the current period from the contribution contract"
        );
    }
}
