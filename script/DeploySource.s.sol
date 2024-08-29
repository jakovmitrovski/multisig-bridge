// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/BridgeDeposit.sol";

//NEED command source.env first
// forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvvv
contract DeploySource is Script {
    address[] signers;

    function run() external {
        signers.push(vm.envAddress("SIGNER_1"));

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Token token = new Token("JToken", "JTK");

        token.mint(vm.envAddress("PUBLIC_KEY"), 10 ** 18);

        BridgeDeposit bridgeDeposit = new BridgeDeposit(signers, uint8(1), uint8(1), uint8(1));

        vm.stopBroadcast();
    }
}
