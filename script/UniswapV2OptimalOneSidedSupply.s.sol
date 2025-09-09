// SPDX-License-Identifier: MIT
// Contract elements should be laid out in the following order:
// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts
// Inside each contract, library or interface, use the following order:
// Type declarations
// State variables
// Events
// Errors
// Modifiers
// Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
//
// internal
// private

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {UniswapV2OptimalOneSideSupply, IERC20} from "src/UniswapV2OptimalOneSideSupply.sol";

contract UniswapV2OptimalOneSideSupplyScript is Script {
    function run() public {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenA = vm.envAddress("TOKENA");
        address tokenB = vm.envAddress("TOKENB");
        address router = vm.envAddress("ROUTER");
        address factory = vm.envAddress("FACTORY");
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        UniswapV2OptimalOneSideSupply zapper;

        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployPrivateKey);

        zapper = new UniswapV2OptimalOneSideSupply(router, factory);
        uint256 amountA = 10 ether;
        IERC20(tokenA).approve(address(zapper), amountA);

        zapper.zap(tokenA, tokenB, amountA);
    }
}
