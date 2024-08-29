// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/BridgeMint.sol";

contract DeploySource is Script {
    address[] signers;

    function run() external {
        signers.push(vm.envAddress("SIGNER_1"));

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token("Wrapped JToken", "WJTK");

        BridgeMint bridgeMint = new BridgeMint(signers, uint8(1), uint8(1), uint8(1));

        token.grantMinterRole(address(bridgeMint));

        vm.stopBroadcast();
    }
}
