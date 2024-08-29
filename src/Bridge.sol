// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IBridge.sol";
import "./MultisigImpl.sol";

import "@forge-std/console2.sol";

abstract contract Bridge is IBridge, MultisigImpl {
    uint8 public bridgeFeePercent;
    uint8 public validatorsFeePercent;
    uint240 public depositCounter;
    address public migration;

    struct Deposit {
        uint240 id;
        uint256 amount;
        uint256 bridgeFee;
        uint256 totalValidatorFee;
        address sourceToken;
        address targetToken;
        address from;
    }

    address[] public supportedTokens;

    mapping(address => bool) public isTokenSupported;

    mapping(address => uint256) public bridgeFeesPerToken;
    mapping(address => mapping(uint8 => uint256)) validatorFeePerToken;

    mapping(uint240 => Deposit) public deposits;
    mapping(address => address) public mirrorTokenAddress;

    modifier notMigrated() {
        if (migration != address(0)) {
            revert ContractAlreadyMigrated();
        }
        _;
    }

    constructor(
        address[] memory _signers,
        uint8 _requiredSignatures,
        uint8 _bridgeFeePercent,
        uint8 _validatorsFeePercent
    ) MultisigImpl(_signers, _requiredSignatures) {
        bridgeFeePercent = _bridgeFeePercent;
        validatorsFeePercent = _validatorsFeePercent;
    }

    function setBridgeFeePercent(uint8 _bridgeFeePercent) external onlyRole(DEFAULT_ADMIN_ROLE) notMigrated {
        if (_bridgeFeePercent > 100) {
            revert InvalidFee();
        }
        bridgeFeePercent = _bridgeFeePercent;
    }

    function setValidatorsFeePercent(uint8 _validatorsFeePercent) external onlyRole(DEFAULT_ADMIN_ROLE) notMigrated {
        if (_validatorsFeePercent > 100) {
            revert InvalidFee();
        }
        validatorsFeePercent = _validatorsFeePercent;
    }

    function handleDeposit(Deposit memory d) internal virtual;

    function deposit(address token, uint256 amount) external override notMigrated {
        if (!isTokenSupported[token] || mirrorTokenAddress[token] == address(0)) {
            revert TokenNotSupported();
        }
        uint256 fee = (amount * bridgeFeePercent) / 100;
        bridgeFeesPerToken[token] += fee;
        uint256 totalValidatorFee = (amount * validatorsFeePercent) / 100;

        if (fee <= 0 || (totalValidatorFee / requiredSignatures) <= 0) {
            revert InvalidAmount();
        }

        Deposit storage d = deposits[depositCounter];
        d.id = depositCounter;
        d.sourceToken = token;
        d.targetToken = mirrorTokenAddress[token];
        d.from = msg.sender;
        d.amount = amount;
        d.bridgeFee = fee;
        d.totalValidatorFee = totalValidatorFee;

        depositCounter++;
        handleDeposit(d);
    }

    function handleBridgeTokens(Deposit memory d) internal virtual;

    function bridge(uint240 requestId, address token, address from, uint256 amount) external override notMigrated {
        bytes32 hash = keccak256(abi.encodePacked(requestId, token, from, amount));

        bool completed = attest(hash);

        uint256 bridgeFee = (amount * bridgeFeePercent) / 100;
        uint256 totalValidatorFee = (amount * validatorsFeePercent) / 100;

        if (completed) {
            Deposit memory d =
                Deposit(requestId, amount, bridgeFee, totalValidatorFee, token, mirrorTokenAddress[token], from);

            handleBridgeTokens(d);

            for (uint8 i = 0; i < signerIndex; i++) {
                if (requests[hash].signatures & (1 << i) > 0) {
                    validatorFeePerToken[mirrorTokenAddress[token]][i] += totalValidatorFee / requiredSignatures;
                }
            }
        }
    }

    function configueMirroring(address token, address mirror) external onlyRole(DEFAULT_ADMIN_ROLE) notMigrated {
        if (mirror == address(0) || token == address(0)) {
            revert InvalidTokenAddress();
        }
        mirrorTokenAddress[token] = mirror;
    }

    function collectBridgeFees(address token) external onlyRole(DEFAULT_ADMIN_ROLE) notMigrated {
        uint256 fees = bridgeFeesPerToken[token];
        if (fees > 0) {
            bridgeFeesPerToken[token] = 0;
            IERC20(token).transfer(msg.sender, fees);
        }
    }

    function addSupportedToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) notMigrated {
        if (isTokenSupported[token]) {
            revert TokenAlreadyAdded();
        }
        supportedTokens.push(token);
        isTokenSupported[token] = true;
    }

    function collectValidatorFees(address token) external onlyRole(SIGNER_ROLE) notMigrated {
        uint8 signerIndex = signers[msg.sender].index;
        uint256 fees = validatorFeePerToken[token][signerIndex];

        if (fees > 0) {
            validatorFeePerToken[token][signerIndex] = 0;
            IERC20(token).transfer(msg.sender, fees);
        }
    }

    function handleMigrate(address newBridge) internal virtual;

    function migrate(address newBridge) external override onlyRole(DEFAULT_ADMIN_ROLE) notMigrated {
        migration = newBridge;
        handleMigrate(newBridge);
    }
}
