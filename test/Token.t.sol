// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address[] initialRecipients;
    address admin = makeAddr("admin");
    address testUser = makeAddr("testUser");
    address minter = makeAddr("minter");
    address recipient = makeAddr("recipient");

    function setUp() public {
        vm.prank(admin);
        token = new Token("TestToken", "TTK");
    }

    function test_AdminRoleAssignment() public {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_GrantRevokeMinterRole() public {
        address newMinter = makeAddr("newMinter");
        vm.prank(admin);
        token.grantMinterRole(newMinter);
        assertTrue(token.hasRole(token.MINTER_ROLE(), newMinter));

        vm.prank(admin);
        token.revokeMinterRole(newMinter);
        assertFalse(token.hasRole(token.MINTER_ROLE(), newMinter));
    }

    function test_Minting() public {
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(minter);
        token.mint(recipient, 500);
        assertEq(token.balanceOf(recipient), 500);
    }

    function test_Burning() public {
        vm.prank(admin);
        token.grantMinterRole(minter);

        vm.prank(minter);
        token.mint(recipient, 500);

        vm.prank(minter);
        token.burn(recipient, 200);

        assertEq(token.balanceOf(recipient), 300);
    }
}
