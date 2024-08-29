// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/BridgeDeposit.sol";

contract ConfigureMirroring is Script {
    function run() external {
        address contractAddress = vm.envAddress("BRIDGE_MINT");
        address sourceToken = vm.envAddress("TOKEN_DEPOSIT");
        address targetToken = vm.envAddress("TOKEN_MINT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Bridge bridge = BridgeDeposit(contractAddress);
        bridge.configueMirroring(sourceToken, targetToken);
        bridge.configueMirroring(targetToken, sourceToken);
        vm.stopBroadcast();
    }
}
