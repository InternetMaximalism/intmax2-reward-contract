// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Minter} from "../../src/minter/Minter.sol";
import {IMinter} from "../../src/minter/IMinter.sol";
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

contract Minter2 is Minter {}

contract MinterTest is Test {
    Minter public minter;
    testIntMaxToken public token;
    address private constant LIQUIDITY = address(0x1);
    address private nonOwner = address(0x2);

    function setUp() public {
        token = new testIntMaxToken();
        Minter implementation = new Minter();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(Minter.initialize.selector, address(token), LIQUIDITY)
        );

        minter = Minter(address(proxy));
    }

    function test_initializeOwnerAddressSet() public view {
        address owner = minter.owner();
        assertEq(owner, address(this));
    }

    function test_initializeZeroAddress1() public {
        Minter implementation = new Minter();
        vm.expectRevert(IMinter.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(Minter.initialize.selector, address(0), LIQUIDITY)
        );
    }

    function test_initializeZeroAddress2() public {
        Minter implementation = new Minter();
        vm.expectRevert(IMinter.AddressZero.selector);

        new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(Minter.initialize.selector, address(1), address(0))
        );
    }

    function test_mintByOwner() public {
        uint256 initialBalance = token.balanceOf(address(minter));
        minter.mint();
        uint256 finalBalance = token.balanceOf(address(minter));
        assertEq(finalBalance, initialBalance + 1000);
    }

    function test_mintByNonOwner() public {
        vm.prank(nonOwner);
        bytes memory expectedRevert =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner);
        vm.expectRevert(expectedRevert);
        minter.mint();
    }

    function test_transferToLiquidity() public {
        minter.mint();
        uint256 amount = 500;

        uint256 initialLiquidityBalance = token.balanceOf(LIQUIDITY);
        minter.transferToLiquidity(amount);
        uint256 finalLiquidityBalance = token.balanceOf(LIQUIDITY);

        assertEq(finalLiquidityBalance, initialLiquidityBalance + amount);
    }

    function test_transferToLiquidityByNonOwner() public {
        minter.mint();
        uint256 amount = 500;

        vm.prank(nonOwner);
        bytes memory expectedRevert =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner);
        vm.expectRevert(expectedRevert);
        minter.transferToLiquidity(amount);
    }

    function test_unauthorizedUpgrade() public {
        vm.prank(nonOwner);
        bytes memory expectedRevert =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nonOwner);
        vm.expectRevert(expectedRevert);
        minter.upgradeToAndCall(address(0x3), "");
    }

    function test_authorizedUpgrade() public {
        Minter2 newImplementation = new Minter2();
        vm.prank(address(this));
        minter.upgradeToAndCall(address(newImplementation), "");
    }
}
