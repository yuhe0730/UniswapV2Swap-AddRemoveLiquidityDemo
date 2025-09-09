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
// public
// internal
// private
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IUniswapV2Router, IUniswapV2Factory, IUniswapV2Pair, IERC20, UniswapV2OptimalOneSideSupply} from "src/UniswapV2OptimalOneSideSupply.sol";

contract UniswapV2OptimalOneSideSupplyTest is Test {
    address public immutable router = vm.envAddress("ROUTER");
    address public immutable factory = vm.envAddress("FACTORY");
    address public immutable tokenA = vm.envAddress("TOKENA");
    address public immutable tokenB = vm.envAddress("TOKENB");
    address public immutable user = vm.envAddress("USER");
    uint256 public immutable unix_time = vm.envUint("UNIX_TIME");
    uint256 public constant SWAP_FEE = 3000; // %0.3 * PRECISION
    uint256 public constant PRECISION = 1e6;
    UniswapV2OptimalOneSideSupply public zapper;
    address pair;

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        zapper = new UniswapV2OptimalOneSideSupply(router, factory);
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        vm.warp(unix_time);
        vm.startPrank(user);
    }

    function testZap() public {
        uint256 amountA = 10 ether;

        IERC20(tokenA).approve(address(zapper), amountA);
        vm.recordLogs();
        zapper.zap(tokenA, tokenB, amountA);

        VmSafe.Log[] memory logs = vm.getRecordedLogs();

        for (uint256 i = 0; i < logs.length; ++i) {
            VmSafe.Log memory log = logs[i];

            if (
                log.topics[0] ==
                keccak256(
                    "Swap(address,uint256,uint256,uint256,uint256,address)"
                )
            ) {
                (
                    uint256 amount0In,
                    uint256 amount1In,
                    uint256 amount0Out,
                    uint256 amount1Out
                ) = abi.decode(log.data, (uint256, uint256, uint256, uint256));
                (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
                    .getReserves();

                if (IUniswapV2Pair(pair).token0() == tokenA) {
                    console.log("tokenA is token0:");
                    console.log((amountA - amount0In), amount1Out);
                    console.log(reserve0, reserve1);

                    assertApproxEqRel(
                        (amountA - amount0In) * reserve1,
                        amount1Out * reserve0,
                        1e5
                    );
                } else {
                    console.log("tokenA is token1:");
                    console.log(amount0Out, (amountA - amount1In));
                    console.log(reserve0, reserve1);
                    assertEq(
                        amount0Out * reserve1,
                        reserve0 * (amountA - amount1In)
                    );
                }
            }
        }
    }
}
