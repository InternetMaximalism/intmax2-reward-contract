// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Minter} from "../../src/minter/Minter.sol";
import {IMinter} from "../../src/minter/IMinter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract testIntMaxToken is ERC20 {
    bool public shouldFailMint;
    bool public shouldMintZero;
    bool public shouldFailTransfer;

    constructor() ERC20("TestIntMaxToken", "TIMT") {}

    function mint(address to) external {
        if (shouldFailMint) {
            // Burn tokens to simulate balance decrease
            if (balanceOf(to) > 0) {
                _burn(to, balanceOf(to));
            }
            return;
        }
        if (shouldMintZero) {
            // Don't mint anything
            return;
        }
        _mint(to, 1000);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (shouldFailTransfer) {
            return false;
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function setShouldFailMint(bool _shouldFail) external {
        shouldFailMint = _shouldFail;
    }

    function setShouldMintZero(bool _shouldMintZero) external {
        shouldMintZero = _shouldMintZero;
    }

    function setShouldFailTransfer(bool _shouldFail) external {
        shouldFailTransfer = _shouldFail;
    }
}

contract Minter2 is Minter {}

contract MinterTest is Test {
    Minter public minter;
    testIntMaxToken public token;
    address private constant LIQUIDITY = address(0x1);
    address private constant ADMIN = address(0x2);
    address private constant TOKEN_MANAGER = address(0x3);
    address private nonAuthorized = address(0x4);

    function setUp() public {
        token = new testIntMaxToken();
        Minter implementation = new Minter();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Minter.initialize.selector, address(token), LIQUIDITY, ADMIN)
        );

        minter = Minter(address(proxy));

        // Grant TOKEN_MANAGER_ROLE to TOKEN_MANAGER address
        vm.startPrank(ADMIN);
        minter.grantRole(minter.TOKEN_MANAGER_ROLE(), TOKEN_MANAGER);
        vm.stopPrank();
    }

    function test_initializeAdminRoleSet() public view {
        bool hasAdminRole = minter.hasRole(minter.DEFAULT_ADMIN_ROLE(), ADMIN);
        assertTrue(hasAdminRole);
    }

    function test_initializeZeroAddress1() public {
        Minter implementation = new Minter();
        vm.expectRevert(IMinter.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(Minter.initialize.selector, address(0), LIQUIDITY, ADMIN)
        );
    }

    function test_initializeZeroAddress2() public {
        Minter implementation = new Minter();
        vm.expectRevert(IMinter.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Minter.initialize.selector, address(token), address(0), ADMIN)
        );
    }

    function test_initializeZeroAddress3() public {
        Minter implementation = new Minter();
        vm.expectRevert(IMinter.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(Minter.initialize.selector, address(token), LIQUIDITY, address(0))
        );
    }

    function test_mintByTokenManager() public {
        uint256 initialBalance = token.balanceOf(address(minter));

        vm.expectEmit(true, false, false, true);
        emit IMinter.Minted(1000);

        vm.prank(TOKEN_MANAGER);
        minter.mint();
        uint256 finalBalance = token.balanceOf(address(minter));
        assertEq(finalBalance, initialBalance + 1000);
    }

    function test_mintByNonAuthorized() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonAuthorized, minter.TOKEN_MANAGER_ROLE()
            )
        );
        vm.prank(nonAuthorized);
        minter.mint();
    }

    function test_transferToLiquidity() public {
        vm.prank(TOKEN_MANAGER);
        minter.mint();
        uint256 amount = 500;

        uint256 initialLiquidityBalance = token.balanceOf(LIQUIDITY);

        vm.expectEmit(true, false, false, true);
        emit IMinter.TransferredToLiquidity(amount);

        vm.prank(TOKEN_MANAGER);
        minter.transferToLiquidity(amount);
        uint256 finalLiquidityBalance = token.balanceOf(LIQUIDITY);

        assertEq(finalLiquidityBalance, initialLiquidityBalance + amount);
    }

    function test_transferToLiquidityByNonAuthorized() public {
        vm.prank(TOKEN_MANAGER);
        minter.mint();
        uint256 amount = 500;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonAuthorized, minter.TOKEN_MANAGER_ROLE()
            )
        );
        vm.prank(nonAuthorized);
        minter.transferToLiquidity(amount);
    }

    function test_unauthorizedUpgrade() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonAuthorized, minter.DEFAULT_ADMIN_ROLE()
            )
        );
        vm.prank(nonAuthorized);
        minter.upgradeToAndCall(address(0x5), "");
    }

    function test_authorizedUpgrade() public {
        Minter2 newImplementation = new Minter2();
        vm.prank(ADMIN);
        minter.upgradeToAndCall(address(newImplementation), "");
    }

    function test_mintEventEmission() public {
        vm.expectEmit(true, false, false, true);
        emit IMinter.Minted(1000);
        vm.prank(TOKEN_MANAGER);
        minter.mint();
    }

    function test_transferToLiquidityEventEmission() public {
        vm.prank(TOKEN_MANAGER);
        minter.mint();
        uint256 amount = 250;

        vm.expectEmit(true, false, false, true);
        emit IMinter.TransferredToLiquidity(amount);
        vm.prank(TOKEN_MANAGER);
        minter.transferToLiquidity(amount);
    }

    function test_transferToByAdmin() public {
        vm.prank(TOKEN_MANAGER);
        minter.mint();
        uint256 amount = 300;
        address recipient = address(0x6);

        vm.expectEmit(true, false, false, true);
        emit IMinter.TransferredTo(recipient, amount);

        vm.prank(ADMIN);
        minter.transferTo(recipient, amount);

        assertEq(token.balanceOf(recipient), amount);
    }

    function test_transferToByNonAdmin() public {
        vm.prank(TOKEN_MANAGER);
        minter.mint();
        uint256 amount = 300;
        address recipient = address(0x6);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonAuthorized, minter.DEFAULT_ADMIN_ROLE()
            )
        );
        vm.prank(nonAuthorized);
        minter.transferTo(recipient, amount);
    }

    function test_mintFailedError() public {
        // First mint some tokens to the minter contract
        vm.prank(TOKEN_MANAGER);
        minter.mint();

        // Set the token to fail mint (simulate balance decrease)
        token.setShouldFailMint(true);

        vm.expectRevert(IMinter.MintFailed.selector);
        vm.prank(TOKEN_MANAGER);
        minter.mint();
    }

    function test_noTokensMintedError() public {
        // Set the token to mint zero tokens
        token.setShouldMintZero(true);

        vm.expectRevert(IMinter.NoTokensMinted.selector);
        vm.prank(TOKEN_MANAGER);
        minter.mint();
    }

    function test_transferToLiquidityZeroAmount() public {
        vm.expectRevert(IMinter.ZeroAmount.selector);
        vm.prank(TOKEN_MANAGER);
        minter.transferToLiquidity(0);
    }

    function test_transferToLiquidityInsufficientBalance() public {
        vm.expectRevert(IMinter.InsufficientBalance.selector);
        vm.prank(TOKEN_MANAGER);
        minter.transferToLiquidity(1000);
    }

    function test_transferToLiquidityTransferFailed() public {
        // First mint tokens
        vm.prank(TOKEN_MANAGER);
        minter.mint();

        // Set transfer to fail
        token.setShouldFailTransfer(true);

        vm.expectRevert(IMinter.TransferFailed.selector);
        vm.prank(TOKEN_MANAGER);
        minter.transferToLiquidity(500);
    }

    function test_transferToZeroRecipient() public {
        vm.expectRevert(IMinter.ZeroRecipient.selector);
        vm.prank(ADMIN);
        minter.transferTo(address(0), 100);
    }

    function test_transferToZeroAmount() public {
        vm.expectRevert(IMinter.ZeroAmount.selector);
        vm.prank(ADMIN);
        minter.transferTo(address(0x7), 0);
    }

    function test_transferToInsufficientBalance() public {
        vm.expectRevert(IMinter.InsufficientBalance.selector);
        vm.prank(ADMIN);
        minter.transferTo(address(0x7), 1000);
    }

    function test_transferToTransferFailed() public {
        // First mint tokens
        vm.prank(TOKEN_MANAGER);
        minter.mint();

        // Set transfer to fail
        token.setShouldFailTransfer(true);

        vm.expectRevert(IMinter.TransferFailed.selector);
        vm.prank(ADMIN);
        minter.transferTo(address(0x7), 500);
    }
}
