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
import {IERC20, UniswapV2SwapDemo} from "src/UniswapV2SwapDemo.sol";

contract UniswapV2SwapDemoScript is Script {
    function run() public {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenA = vm.envAddress("TOKENA");
        address tokenB = vm.envAddress("TOKENB");
        address tokenC = vm.envAddress("TOKENC");
        address router = vm.envAddress("ROUTER");
        uint256 unix_time = vm.envUint("UNIX_TIME");
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        UniswapV2SwapDemo swapper;

        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployPrivateKey);

        swapper = new UniswapV2SwapDemo(router);

        IERC20(tokenA).approve(address(swapper), 10 ether);
        uint256 actualAmountOut = swapper.swapExactAmountIn(
            tokenA,
            tokenB,
            10 ether,
            1 ether,
            unix_time + 10000
        );
        console.log("actualAmountOut:", actualAmountOut);

        IERC20(tokenA).approve(address(swapper), 10 ether);
        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = tokenB;
        path[2] = tokenC;
        uint256 actualAmountIn = swapper.swapMultiHopExactAmountOut(
            path,
            10 ether,
            1 ether,
            unix_time + 10000
        );
        console.log("actualAmountIn:", actualAmountIn);

        vm.stopBroadcast();
    }
}
