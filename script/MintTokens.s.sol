// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract MintTokens is Script {
    function run() external {
        address tokenAddress = vm.envAddress("TOKEN_DEPOSIT");
        address mintTo = vm.envAddress("PUBLIC_KEY");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 amount = 1000 * 1e18;

        Token token = Token(tokenAddress);

        vm.startBroadcast(deployerPrivateKey);

        token.mint(mintTo, amount);

        vm.stopBroadcast();
    }
}
