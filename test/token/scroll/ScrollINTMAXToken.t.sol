// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ScrollINTMAXToken} from "../../../src/token/scroll/ScrollINTMAXToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ScrollINTMAXTokenTest is Test {
    ScrollINTMAXToken public tokenImpl;
    ScrollINTMAXToken public token;
    ERC1967Proxy public proxy;

    address public admin = address(0x1);
    address public rewardContract = address(0x2);
    uint256 public constant MINT_AMOUNT = 1000000e18;

    function setUp() public {
        tokenImpl = new ScrollINTMAXToken();

        bytes memory data =
            abi.encodeWithSelector(ScrollINTMAXToken.initialize.selector, admin, rewardContract, MINT_AMOUNT);

        proxy = new ERC1967Proxy(address(tokenImpl), data);
        token = ScrollINTMAXToken(address(proxy));
    }

    function test_InitializeDirectlyOnImplementationFails() public {
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        tokenImpl.initialize(admin, rewardContract, MINT_AMOUNT);
    }

    function test_InitializeOnProxyWorks() public view {
        assertEq(token.name(), "ScrollINTMAX");
        assertEq(token.symbol(), "sITX");
        assertEq(token.balanceOf(rewardContract), MINT_AMOUNT);
        assertTrue(token.hasRole(token.DISTRIBUTOR(), rewardContract));
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertFalse(token.transfersAllowed());
    }

    function test_ReInitializeOnProxyFails() public {
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        token.initialize(admin, rewardContract, MINT_AMOUNT);
    }

    function test_DisableInitializersBlocksImplementationInit() public {
        ScrollINTMAXToken newImpl = new ScrollINTMAXToken();

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        newImpl.initialize(address(0x3), address(0x4), 1000e18);
    }
}
