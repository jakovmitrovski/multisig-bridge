// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBridge {
    event TokensLocked(uint240 indexed requestId, address token, address to, uint256 amount);
    event RequestCompleted(
        uint240 indexed requestId, address sourceToken, address targetToken, address from, uint256 amount
    );

    error InvalidAmount();
    error InvalidDeposit();
    error InvalidFee();
    error InvalidTokenAddress();
    error ContractAlreadyMigrated();
    error TokenAlreadyAdded();

    error TokenNotSupported();

    function setBridgeFeePercent(uint8 _bridgeFeePercent) external;
    function setValidatorsFeePercent(uint8 _validatorsFeePercent) external;
    function deposit(address token, uint256 amount) external;
    function bridge(uint240 requestId, address token, address from, uint256 amount) external;
    function configueMirroring(address token, address mirror) external;
    function collectBridgeFees(address token) external;
    function collectValidatorFees(address token) external;
    function migrate(address newBridge) external;
}
