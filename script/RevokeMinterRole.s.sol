// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract GrantMinterRole is Script {
    function run() external {
        address tokenAddress = vm.envAddress("TOKEN_DEPOSIT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address minter = makeAddr("MINTER");

        Token token = Token(tokenAddress);

        vm.startBroadcast(deployerPrivateKey);

        token.revokeMinterRole(minter);

        vm.stopBroadcast();
    }
}
