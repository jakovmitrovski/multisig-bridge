// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "../src/BridgeDeposit.sol";
import "../src/BridgeMint.sol";

import "@forge-std/console2.sol";

contract BridgeTest is Test {
    event TokensLocked(uint240 indexed requestId, address token, address to, uint256 amount);
    event RequestCompleted(
        uint240 indexed requestId, address sourceToken, address targetToken, address from, uint256 amount
    );

    Token token1;
    Token token2;
    BridgeDeposit bridgeDeposit;
    BridgeMint bridgeMint;
    address admin = makeAddr("admin");
    address[] signers;
    address testUser = makeAddr("testUser");
    address newBridge = makeAddr("newBridge");
    address newBridge2 = makeAddr("newBridge2");

    bytes32 public DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        vm.startPrank(admin);

        token1 = new Token("Token1", "TKN1");

        token1.mint(testUser, 1000 * 1e18);

        for (uint256 i = 0; i < 5; i++) {
            signers.push(makeAddr(string(abi.encodePacked("signer", i))));
        }

        bridgeDeposit = new BridgeDeposit(signers, 3, 2, 5);
        bridgeMint = new BridgeMint(signers, 3, 4, 3);

        vm.stopPrank();

        vm.prank(address(bridgeMint));

        token2 = new Token("Token2", "TKN2");

        vm.startPrank(admin);

        bridgeDeposit.addSupportedToken(address(token1));
        bridgeMint.addSupportedToken(address(token2));

        bridgeDeposit.configueMirroring(address(token1), address(token2));
        bridgeDeposit.configueMirroring(address(token2), address(token1));
        bridgeMint.configueMirroring(address(token1), address(token2));
        bridgeMint.configueMirroring(address(token2), address(token1));

        vm.stopPrank();
    }

    function test_SetBridgeFeePercent() public {
        uint8 feePercent = 100;

        vm.startPrank(admin);
        bridgeDeposit.setValidatorsFeePercent(feePercent);
        bridgeMint.setValidatorsFeePercent(uint8(100) - feePercent);

        assertEq(bridgeDeposit.validatorsFeePercent(), feePercent);
        assertEq(bridgeMint.validatorsFeePercent(), uint8(100) - feePercent);
        vm.stopPrank();
    }

    function test_SetValidatorsFeePercent() public {
        uint8 feePercent = 50;

        vm.startPrank(admin);
        bridgeDeposit.setValidatorsFeePercent(feePercent);
        bridgeMint.setValidatorsFeePercent(uint8(100) - feePercent);

        assertEq(bridgeDeposit.validatorsFeePercent(), feePercent);
        assertEq(bridgeMint.validatorsFeePercent(), uint8(100) - feePercent);
        vm.stopPrank();
    }

    function test_SetInvalidFeePercent() public {
        bytes4 selector = bytes4(keccak256("InvalidFee()"));
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.setValidatorsFeePercent(uint8(101));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.setBridgeFeePercent(uint8(101));
        vm.stopPrank();
    }

    function test_NonAdminCannotSetBridgeFeePercent() public {
        uint8 feePercent = 100;
        vm.startPrank(testUser);
        vm.expectRevert();
        bridgeDeposit.setBridgeFeePercent(feePercent);
        vm.stopPrank();
    }

    function test_NonAdminCannotSetValidatorsFeePercent() public {
        uint8 feePercent = 50;
        vm.startPrank(testUser);
        vm.expectRevert();
        bridgeDeposit.setValidatorsFeePercent(feePercent);
        vm.stopPrank();
    }

    function test__Migrate() public {
        bytes4 selector = bytes4(keccak256("ContractAlreadyMigrated()"));
        uint256 amount = 10 * 1e18;

        assertEq(token1.balanceOf(newBridge), 0);
        assertEq(token2.balanceOf(newBridge2), 0);

        vm.prank(address(bridgeMint));
        token2.mint(address(bridgeMint), amount);

        vm.startPrank(admin);
        token1.mint(address(bridgeDeposit), amount);
        bridgeDeposit.migrate(newBridge);
        bridgeMint.migrate(newBridge2);
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.migrate(newBridge);
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.setBridgeFeePercent(uint8(100));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.setValidatorsFeePercent(uint8(100));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.addSupportedToken(address(token1));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.collectBridgeFees(address(token1));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bridgeDeposit.bridge(0, address(token1), testUser, 1000);
        vm.stopPrank();
        assertEq(token1.balanceOf(newBridge), amount);
        assertEq(token2.balanceOf(newBridge2), amount);
    }

    function test_CantMigrate() public {
        vm.startPrank(testUser);
        vm.expectRevert();
        bridgeDeposit.migrate(newBridge);
        vm.stopPrank();
    }

    function test_UserDepositsToBridgeDepositAndBridgesViaBridgeMint() public {
        uint240 requestId = uint240(0);
        uint256 amount = 5 * 1e18;
        vm.startPrank(testUser);
        token1.approve(address(bridgeDeposit), amount);

        vm.expectEmit(true, true, false, true);
        emit TokensLocked(requestId, address(token1), testUser, amount);

        bridgeDeposit.deposit(address(token1), amount);

        vm.stopPrank();

        for (uint8 i = 0; i < bridgeMint.requiredSignatures(); i++) {
            if (i == bridgeMint.requiredSignatures() - 1) {
                vm.expectEmit(true, true, false, true);
                emit RequestCompleted(requestId, address(token1), address(token2), testUser, amount);
            }
            vm.prank(signers[i]);
            bridgeMint.bridge(requestId, address(token1), testUser, amount);
        }

        uint256 totalFees = ((bridgeMint.bridgeFeePercent() + bridgeMint.validatorsFeePercent()) * amount) / 100;

        uint256 finalAmountReceived = amount - totalFees;
        assertEq(token2.balanceOf(testUser), finalAmountReceived, "User received invalid amount of tokens");
        assertEq(token2.balanceOf(address(bridgeMint)), totalFees, "BridgeMint received invalid fee");
        assertEq(token1.balanceOf(address(bridgeDeposit)), amount, "BridgeDeposit didn't receive tokens");

        for (uint8 i = 0; i < bridgeMint.requiredSignatures(); i++) {
            assertEq(token2.balanceOf(signers[i]), 0);
            vm.prank(signers[i]);
            bridgeMint.collectValidatorFees(address(token2));
            assertEq(
                token2.balanceOf(signers[i]),
                (bridgeMint.validatorsFeePercent() * amount) / 100 / bridgeMint.requiredSignatures(),
                "Signer received invalid fee"
            );
        }

        assertEq(token2.balanceOf(signers[4]), 0);
        vm.prank(signers[4]);
        bridgeMint.collectValidatorFees(address(token2));
        assertEq(token2.balanceOf(signers[4]), 0, "Signer that didn't sign received fee");
    }

    function test_UserDepositsToBridgeMintAndBridgesBackViaBridgeDeposit() public {
        uint240 requestId = uint240(0);
        uint256 amount = 5 * 1e18;

        vm.startPrank(testUser);
        token1.approve(address(bridgeDeposit), amount);

        vm.expectEmit(true, true, false, true);
        emit TokensLocked(requestId, address(token1), testUser, amount);

        bridgeDeposit.deposit(address(token1), amount);

        vm.stopPrank();

        for (uint8 i = 0; i < bridgeMint.requiredSignatures(); i++) {
            if (i == bridgeMint.requiredSignatures() - 1) {
                vm.expectEmit(true, true, false, true);
                emit RequestCompleted(requestId, address(token1), address(token2), testUser, amount);
            }
            vm.prank(signers[i]);
            bridgeMint.bridge(requestId, address(token1), testUser, amount);
        }

        uint256 totalFees = ((bridgeMint.bridgeFeePercent() + bridgeMint.validatorsFeePercent()) * amount) / 100;
        uint256 finalAmountReceived = amount - totalFees;

        assertEq(token2.balanceOf(testUser), finalAmountReceived, "User received invalid amount of tokens");
        assertEq(token2.balanceOf(address(bridgeMint)), totalFees, "BridgeMint received invalid fee");
        assertEq(token1.balanceOf(address(bridgeDeposit)), amount, "BridgeDeposit didn't receive tokens");

        for (uint8 i = 0; i < bridgeMint.requiredSignatures(); i++) {
            assertEq(token2.balanceOf(signers[i]), 0);
            vm.prank(signers[i]);
            bridgeMint.collectValidatorFees(address(token2));
            assertEq(
                token2.balanceOf(signers[i]),
                (bridgeMint.validatorsFeePercent() * amount) / 100 / bridgeMint.requiredSignatures(),
                "Signer received invalid fee"
            );
        }

        assertEq(token2.balanceOf(signers[4]), 0);
        vm.prank(signers[4]);
        bridgeMint.collectValidatorFees(address(token2));
        assertEq(token2.balanceOf(signers[4]), 0, "Signer that didn't sign received fee");

        vm.startPrank(testUser);
        token2.approve(address(bridgeMint), finalAmountReceived);

        vm.expectEmit(true, true, false, true);
        emit TokensLocked(requestId, address(token2), testUser, finalAmountReceived);

        uint256 initialBalanceUser = token1.balanceOf(testUser);
        uint256 initialBalanceBridgeMint = token2.balanceOf(address(bridgeMint));

        bridgeMint.deposit(address(token2), finalAmountReceived);

        vm.stopPrank();

        for (uint8 i = 0; i < bridgeDeposit.requiredSignatures(); i++) {
            if (i == bridgeDeposit.requiredSignatures() - 1) {
                vm.expectEmit(true, true, false, true);
                emit RequestCompleted(requestId, address(token2), address(token1), testUser, finalAmountReceived);
            }
            vm.prank(signers[i]);
            bridgeDeposit.bridge(requestId, address(token2), testUser, finalAmountReceived);
        }

        totalFees =
            ((bridgeDeposit.bridgeFeePercent() + bridgeDeposit.validatorsFeePercent()) * finalAmountReceived) / 100;
        uint256 finalAmountReceivedBack = finalAmountReceived - totalFees;

        assertEq(
            token1.balanceOf(testUser),
            initialBalanceUser + finalAmountReceivedBack,
            "User received invalid amount of tokens back"
        );
        assertEq(
            token1.balanceOf(address(bridgeDeposit)),
            amount - finalAmountReceivedBack,
            "BridgeDeposit received invalid fee"
        );

        assertEq(
            token2.balanceOf(address(bridgeMint)),
            initialBalanceBridgeMint + totalFees,
            "BridgeMint didn't receive tokens"
        );

        for (uint8 i = 0; i < bridgeDeposit.requiredSignatures(); i++) {
            assertEq(token1.balanceOf(signers[i]), 0);
            vm.prank(signers[i]);
            bridgeDeposit.collectValidatorFees(address(token1));
            assertEq(
                token1.balanceOf(signers[i]),
                (bridgeDeposit.validatorsFeePercent() * finalAmountReceived) / 100 / bridgeDeposit.requiredSignatures(),
                "Signer received invalid fee"
            );
        }

        assertEq(token1.balanceOf(signers[4]), 0);
        vm.prank(signers[4]);
        bridgeDeposit.collectValidatorFees(address(token1));
        assertEq(token1.balanceOf(signers[4]), 0, "Signer that didn't sign received fee");
    }
}
