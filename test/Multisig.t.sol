// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MultisigImpl.sol";

contract MultiSigImplTest is Test {
    MultisigImpl multiSig;
    address[] signers;
    address admin = makeAddr("admin");

    function setUp() public {
        for (uint256 i = 0; i < 5; i++) {
            signers.push(makeAddr(string(abi.encodePacked("signer", i))));
        }
        vm.prank(admin);

        multiSig = new MultisigImpl(signers, 3);
    }

    function test_ConstructorInitialization() public view {
        assertEq(multiSig.requiredSignatures(), 3);
        assertEq(multiSig.signerIndex(), 5);
        for (uint256 i = 0; i < 5; i++) {
            assertTrue(multiSig.hasRole(multiSig.SIGNER_ROLE(), signers[i]));
        }
    }

    function test_AddSigner() public {
        address newSigner = makeAddr("signer6");
        vm.prank(admin);
        multiSig.addSigner(newSigner);
        assertTrue(multiSig.hasRole(multiSig.SIGNER_ROLE(), newSigner));
        assertEq(multiSig.signerIndex(), 6);
    }

    function test_RemoveSigner() public {
        vm.prank(admin);
        multiSig.removeSigner(signers[4]);
        assertFalse(multiSig.hasRole(multiSig.SIGNER_ROLE(), signers[4]));
    }

    function test_AddExistingSigner() public {
        bytes4 selector = bytes4(keccak256("SignerAlreadyExists(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, signers[0]));
        vm.prank(admin);
        multiSig.addSigner(signers[0]);
    }

    function test_RemoveNonExistingSigner() public {
        bytes4 selector = bytes4(keccak256("NotASigner(address)"));
        address notASigner = makeAddr("notASigner");
        vm.expectRevert(abi.encodeWithSelector(selector, notASigner));
        vm.prank(admin);
        multiSig.removeSigner(notASigner);
    }

    function test_Attest() public {
        bytes32 hash = keccak256("test request");
        vm.prank(signers[0]);
        bool completed = multiSig.attest(hash);
        assertFalse(completed);
        vm.prank(signers[1]);
        completed = multiSig.attest(hash);
        assertFalse(completed);
        vm.prank(signers[2]);
        completed = multiSig.attest(hash);
        assertTrue(completed);
        assertTrue(multiSig.isCompleted(hash));
        assertTrue(multiSig.getRequestSignatures(hash) >= 3);
    }

    function test_SignerAlreadySigned() public {
        bytes32 hash = keccak256("unique request");
        vm.prank(signers[0]);
        multiSig.attest(hash);

        vm.prank(signers[0]);
        bytes4 selector = bytes4(keccak256("SignerAlreadySigned(bytes32)"));
        vm.expectRevert(abi.encodeWithSelector(selector, hash));
        multiSig.attest(hash);
    }

    function test_InvalidSignerAddress() public {
        address invalidSigner = address(0);
        vm.prank(admin);

        bytes4 selector = bytes4(keccak256("InvalidSigner()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        multiSig.addSigner(invalidSigner);
    }

    function test_MaximumSignersReached() public {
        for (uint256 i = 5; i < 255; i++) {
            address newSigner = makeAddr(string(abi.encodePacked("signer", i)));
            vm.prank(admin);
            multiSig.addSigner(newSigner);
        }

        address extraSigner = makeAddr(string(abi.encodePacked("signer", uint256(256))));
        vm.prank(admin);

        bytes4 selector = bytes4(keccak256("MaxSignersReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        multiSig.addSigner(extraSigner);
    }

    function test_CannotSignCompletedRequest() public {
        bytes32 hash = keccak256("test request");
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(signers[i]);
            multiSig.attest(hash);
        }

        bytes4 selector = bytes4(keccak256("RequestAlreadyCompleted(bytes32)"));
        vm.expectRevert(abi.encodeWithSelector(selector, hash));
        vm.prank(signers[4]);
        multiSig.attest(hash);
    }
}
