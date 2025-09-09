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

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract UniswapV2OptimalOneSideSupply {
    address public immutable router;
    address public immutable factory;
    uint256 public constant SWAP_FEE = 3000; // %0.3 * PRECISION
    uint256 public constant PRECISION = 1e6;

    constructor(address _router, address _factory) {
        router = _router;
        factory = _factory;
    }

    function zap(address tokenA, address tokenB, uint256 amountA) external {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();

        uint256 swapAmount;
        if (IUniswapV2Pair(pair).token0() == tokenA) {
            swapAmount = getSwapAmount(reserve0, amountA, SWAP_FEE, PRECISION);
        } else {
            swapAmount = getSwapAmount(reserve1, amountA, SWAP_FEE, PRECISION);
        }

        swap(tokenA, tokenB, swapAmount);

        addLiquidity(tokenA, tokenB);
    }

    function getSwapAmount(
        uint256 r,
        uint256 a,
        uint256 f,
        uint256 precision
    ) internal pure returns (uint256) {
        return
            (sqrt(
                ((2 * precision - f) * r) ** 2 +
                    4 *
                    precision *
                    (precision - f) *
                    a *
                    r
            ) - (2 * precision - f) * r) / (2 * (precision - f));
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function swap(address tokenA, address tokenB, uint256 amount) internal {
        IERC20(tokenA).approve(router, amount);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        IUniswapV2Router(router).swapExactTokensForTokens(
            amount,
            1,
            path,
            address(this),
            block.timestamp + 1
        );
    }

    function addLiquidity(address tokenA, address tokenB) internal {
        uint256 amountA = IERC20(tokenA).balanceOf(address(this));
        uint256 amountB = IERC20(tokenB).balanceOf(address(this));
        IERC20(tokenA).approve(router, amountA);
        IERC20(tokenB).approve(router, amountB);

        IUniswapV2Router(router).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            1,
            1,
            msg.sender,
            block.timestamp + 1
        );
    }
}
