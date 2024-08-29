// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Bridge.sol";

contract BridgeDeposit is Bridge {
    constructor(
        address[] memory _signers,
        uint8 _requiredSignatures,
        uint8 _bridgeFeePercent,
        uint8 _validatorsFeePercent
    ) Bridge(_signers, _requiredSignatures, _bridgeFeePercent, _validatorsFeePercent) {}

    function handleDeposit(Deposit memory deposit) internal override {
        IERC20(deposit.sourceToken).transferFrom(deposit.from, address(this), deposit.amount);
        emit TokensLocked(deposit.id, deposit.sourceToken, deposit.from, deposit.amount);
    }

    function handleBridgeTokens(Deposit memory deposit) internal override {
        IERC20(deposit.targetToken).transfer(
            deposit.from, deposit.amount - deposit.bridgeFee - deposit.totalValidatorFee
        );
        emit RequestCompleted(deposit.id, deposit.sourceToken, deposit.targetToken, deposit.from, deposit.amount);
    }

    function handleMigrate(address newBridge) internal override {
        for (uint240 i = 0; i < supportedTokens.length; i++) {
            IERC20 token = IERC20(supportedTokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            token.transfer(newBridge, balance);
        }
    }
}
