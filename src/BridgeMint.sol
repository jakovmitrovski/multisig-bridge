// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Bridge.sol";
import "./interfaces/IMintAndBurnERC20.sol";

import "@forge-std/console2.sol";

contract BridgeMint is Bridge {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        address[] memory _signers,
        uint8 _requiredSignatures,
        uint8 _bridgeFeePercent,
        uint8 _validatorsFeePercent
    ) Bridge(_signers, _requiredSignatures, _bridgeFeePercent, _validatorsFeePercent) {}

    function handleDeposit(Deposit memory deposit) internal override {
        IMintAndBurnERC20(deposit.sourceToken).burn(
            deposit.from, deposit.amount - deposit.bridgeFee - deposit.totalValidatorFee
        );
        IERC20(deposit.sourceToken).transferFrom(
            deposit.from, address(this), deposit.bridgeFee + deposit.totalValidatorFee
        );
        emit TokensLocked(deposit.id, deposit.sourceToken, deposit.from, deposit.amount);
    }

    function handleBridgeTokens(Deposit memory deposit) internal override {
        IMintAndBurnERC20(deposit.targetToken).mint(
            deposit.from, deposit.amount - deposit.bridgeFee - deposit.totalValidatorFee
        );
        IMintAndBurnERC20(deposit.targetToken).mint(address(this), deposit.bridgeFee + deposit.totalValidatorFee);
        emit RequestCompleted(deposit.id, deposit.sourceToken, deposit.targetToken, deposit.from, deposit.amount);
    }

    function handleMigrate(address newBridge) internal override {
        for (uint240 i = 0; i < supportedTokens.length; i++) {
            IMintAndBurnERC20 token = IMintAndBurnERC20(supportedTokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            token.burn(address(this), balance);
            token.mint(newBridge, balance);

            token.grantRole(MINTER_ROLE, newBridge);
            token.grantRole(DEFAULT_ADMIN_ROLE, newBridge);
            token.renounceRole(MINTER_ROLE, address(this));
            token.renounceRole(DEFAULT_ADMIN_ROLE, address(this));
        }
    }
}
