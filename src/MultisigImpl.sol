// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import "./interfaces/IMultisig.sol";

contract MultisigImpl is IMultisig, AccessControlEnumerable {
    uint8 public requiredSignatures;
    uint8 public constant MAX_SIGNERS = 255;
    uint8 public signerIndex;
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    struct Request {
        uint256 signatures;
        uint8 signatureCount;
        bool completed;
    }

    struct Signer {
        address signerAddress;
        uint8 index;
        bool active;
    }

    mapping(address => Signer) public signers;
    mapping(bytes32 => Request) public requests;

    constructor(address[] memory _signers, uint8 _requiredSignatures) {
        requiredSignatures = _requiredSignatures;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _signers.length; i++) {
            addSigner(_signers[i]);
        }
    }

    function resetSignerData() public override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 roleCount = getRoleMemberCount(SIGNER_ROLE);

        for (uint256 i = 0; i < roleCount; i++) {
            address signerAddress = getRoleMember(SIGNER_ROLE, i);
            _revokeRole(SIGNER_ROLE, signerAddress);
            delete signers[signerAddress];
        }
        signerIndex = 0;
    }

    function addSigner(address _signer) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (signers[_signer].active) {
            revert SignerAlreadyExists(_signer);
        }
        if (_signer == address(0)) {
            revert InvalidSigner();
        }
        if (signerIndex >= MAX_SIGNERS) {
            revert MaxSignersReached();
        }
        signers[_signer] = Signer(_signer, signerIndex, true);
        signerIndex++;
        _grantRole(SIGNER_ROLE, _signer);
    }

    function removeSigner(address _signer) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!signers[_signer].active) {
            revert NotASigner(_signer);
        }
        signers[_signer].active = false;
        _revokeRole(SIGNER_ROLE, _signer);
    }

    function attest(bytes32 _hash) public override onlyRole(SIGNER_ROLE) returns (bool) {
        Request storage request = requests[_hash];

        if (request.completed) {
            revert RequestAlreadyCompleted(_hash);
        }

        Signer memory signer = signers[msg.sender];

        if ((request.signatures & (1 << signer.index)) != 0) {
            revert SignerAlreadySigned(_hash);
        }
        request.signatures |= (1 << signer.index);
        request.signatureCount++;
        emit Signed(_hash, msg.sender);
        if (request.signatureCount >= requiredSignatures) {
            request.completed = true;
        }

        return request.completed;
    }

    function getRequestSignatures(bytes32 _hash) public view override returns (uint256) {
        return requests[_hash].signatures;
    }

    function isCompleted(bytes32 _hash) public view override returns (bool) {
        return requests[_hash].completed;
    }

    function setRequiredSignatures(uint8 _requiredSignatures) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        requiredSignatures = _requiredSignatures;
    }
}
