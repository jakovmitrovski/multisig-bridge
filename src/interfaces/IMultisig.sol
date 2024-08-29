// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMultisig {
    event Signed(bytes32 indexed _hash, address indexed _signer);

    error InvalidSigner();
    error NotASigner(address addr);
    error MaxSignersReached();
    error InvalidNumberOfSigners();
    error SignerAlreadyExists(address addr);
    error SignerAlreadySigned(bytes32 _hash);
    error RequestAlreadyCompleted(bytes32 _hash);

    function resetSignerData() external;
    function addSigner(address signer) external;
    function removeSigner(address signer) external;
    function attest(bytes32 _hash) external returns (bool);
    function getRequestSignatures(bytes32 _hash) external view returns (uint256);
    function isCompleted(bytes32 _hash) external view returns (bool);
    function setRequiredSignatures(uint8 _requiredSignatures) external;
}
