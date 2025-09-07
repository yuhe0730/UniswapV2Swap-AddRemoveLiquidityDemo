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
import {IERC20, IUniswapV2Factory, UniswapV2AddRemoveLiquidityDemo} from "src/UniswapV2AddRemoveLiquidityDemo.sol";

contract UniswapV2AddRemoveLiquidityDemoScript is Script {
    function run() public {
        uint256 deployPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenA = vm.envAddress("TOKENA");
        address tokenB = vm.envAddress("TOKENB");
        address router = vm.envAddress("ROUTER");
        address factory = vm.envAddress("FACTORY");
        uint256 unix_time = vm.envUint("UNIX_TIME");
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        UniswapV2AddRemoveLiquidityDemo lpProvider;
        address pair;

        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(deployPrivateKey);

        lpProvider = new UniswapV2AddRemoveLiquidityDemo(router, factory);

        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        IERC20(tokenA).approve(address(lpProvider), 100 ether);
        IERC20(tokenB).approve(address(lpProvider), 200 ether);

        (, , uint256 liquidity) = lpProvider.addLiquidity(
            tokenA,
            tokenB,
            100 ether,
            200 ether,
            1 ether,
            1 ether,
            unix_time + 100000
        );
        console.log("liquidity:", liquidity);

        IERC20(pair).approve(address(lpProvider), liquidity);

        (uint256 amountA, uint256 amountB) = lpProvider.removeLiquidity(
            tokenA,
            tokenB,
            1 ether,
            1 ether,
            liquidity / 2,
            unix_time + 100000
        );
        console.log("amountA:", amountA, "amountB:", amountB);

        vm.stopBroadcast();
    }
}
