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

    function test_claimReward_zeroTotalContributions() public {
        // Set up reward for period 1
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        // Set current period to 2 (period 1 has ended)
        contribution.setCurrentPeriod(2);

        // Set total contributions to 0 (no one contributed)
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 0);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 0);

        // Claim reward should revert with TriedToClaimZeroReward when total contributions is 0
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.TriedToClaimZeroReward.selector);
        builder.claimReward(1);
    }

    function test_getClaimableReward_zeroTotalContributions() public {
        // Set up reward for period 1
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        // Set current period to 2 (period 1 has ended)
        contribution.setCurrentPeriod(2);

        // Set total contributions to 0
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 0);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Should return 0 when total contributions is 0
        uint256 claimableReward = builder.getClaimableReward(1, user1);
        assertEq(claimableReward, 0, "Should return 0 when total contributions is 0");
    }

    function test_setReward_maxUint248() public {
        // Test setting reward with maximum uint248 value
        uint256 maxAmount = uint256(type(uint248).max);

        vm.prank(rewardManager);
        builder.setReward(1, maxAmount);

        (bool isSet, uint256 amount) = builder.getReward(1);
        assertEq(isSet, true, "Reward should be set");
        assertEq(amount, maxAmount, "Amount should equal max uint248");
    }

    function test_claimReward_precisionLoss() public {
        // Test reward calculation with potential precision loss
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 3);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 1);

        vm.prank(user1);
        builder.claimReward(1);

        // Expected: 1000 * 1 / 3 = 333 (integer division)
        assertEq(token.balanceOf(user1), 333, "Should handle integer division correctly");
    }

    function test_batchClaimReward_singlePeriod() public {
        // Test batch claim with only one period
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        uint256[] memory periodNumbers = new uint256[](1);
        periodNumbers[0] = 1;

        vm.prank(user1);
        builder.batchClaimReward(periodNumbers);

        assertEq(token.balanceOf(user1), 500, "Should claim correct amount for single period");
        assertTrue(builder.claimed(1, user1), "Should mark period as claimed");
    }

    function test_multipleUsers_claimReward() public {
        address user2 = address(0x2);
        address user3 = address(0x3);

        // Set up reward
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        contribution.setCurrentPeriod(2);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);

        // Set different contributions for different users
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50); // 50%
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user2, 30); // 30%
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user3, 20); // 20%

        // Each user claims their reward
        vm.prank(user1);
        builder.claimReward(1);

        vm.prank(user2);
        builder.claimReward(1);

        vm.prank(user3);
        builder.claimReward(1);

        // Verify rewards
        assertEq(token.balanceOf(user1), 500, "User1 should receive 50% of reward");
        assertEq(token.balanceOf(user2), 300, "User2 should receive 30% of reward");
        assertEq(token.balanceOf(user3), 200, "User3 should receive 20% of reward");

        // Verify all are marked as claimed
        assertTrue(builder.claimed(1, user1), "User1 should be marked as claimed");
        assertTrue(builder.claimed(1, user2), "User2 should be marked as claimed");
        assertTrue(builder.claimed(1, user3), "User3 should be marked as claimed");
    }

    function test_getClaimableReward_multipleScenarios() public {
        address user2 = address(0x2);

        // Set up rewards for multiple periods
        vm.startPrank(rewardManager);
        builder.setReward(1, 1000);
        builder.setReward(2, 2000);
        vm.stopPrank();

        contribution.setCurrentPeriod(3);

        // Period 1: user1 has 50% contribution
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user2, 0);

        // Period 2: user2 has 75% contribution
        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 200);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 50);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user2, 150);

        // Check claimable rewards before claiming
        assertEq(builder.getClaimableReward(1, user1), 500, "User1 should be able to claim 500 from period 1");
        assertEq(builder.getClaimableReward(1, user2), 0, "User2 should be able to claim 0 from period 1");
        assertEq(builder.getClaimableReward(2, user1), 500, "User1 should be able to claim 500 from period 2");
        assertEq(builder.getClaimableReward(2, user2), 1500, "User2 should be able to claim 1500 from period 2");

        // User1 claims period 1
        vm.prank(user1);
        builder.claimReward(1);

        // Check claimable rewards after user1 claims period 1
        assertEq(builder.getClaimableReward(1, user1), 0, "User1 should not be able to claim from period 1 again");
        assertEq(builder.getClaimableReward(2, user1), 500, "User1 should still be able to claim from period 2");
        assertEq(builder.getClaimableReward(2, user2), 1500, "User2 should still be able to claim from period 2");
    }

    function test_batchClaimReward_partialSuccess() public {
        // Set up rewards for periods 1 and 3, but not 2
        vm.startPrank(rewardManager);
        builder.setReward(1, 1000);
        builder.setReward(3, 3000);
        // Period 2 has no reward set
        vm.stopPrank();

        contribution.setCurrentPeriod(4);

        // Set contributions for all periods
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        contribution.setTotalContribution(2, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(2, keccak256("POST_BLOCK"), user1, 50);

        contribution.setTotalContribution(3, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(3, keccak256("POST_BLOCK"), user1, 50);

        // Try to batch claim periods 1, 2, 3 (period 2 should fail)
        uint256[] memory periodNumbers = new uint256[](3);
        periodNumbers[0] = 1;
        periodNumbers[1] = 2; // This will fail - no reward set
        periodNumbers[2] = 3;

        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.NotSetReward.selector);
        builder.batchClaimReward(periodNumbers);

        // Verify that period 1 was not claimed due to the failure
        assertEq(token.balanceOf(user1), 0, "No rewards should be claimed due to batch failure");
        assertFalse(builder.claimed(1, user1), "Period 1 should not be marked as claimed");
    }

    function test_edge_case_currentPeriodEqualsClaimPeriod() public {
        // Test the edge case where current period equals the claim period
        vm.prank(rewardManager);
        builder.setReward(1, 1000);

        // Set current period to 1 (same as claim period)
        contribution.setCurrentPeriod(1);
        contribution.setTotalContribution(1, keccak256("POST_BLOCK"), 100);
        contribution.setUserContribution(1, keccak256("POST_BLOCK"), user1, 50);

        // Should revert because period has not ended
        vm.prank(user1);
        vm.expectRevert(IBlockBuilderReward.PeriodNotEnded.selector);
        builder.claimReward(1);

        // getClaimableReward should also return 0
        uint256 claimable = builder.getClaimableReward(1, user1);
        assertEq(claimable, 0, "Should return 0 when period has not ended");
    }
}
