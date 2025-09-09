# UniSwap V2 Demo

A simple Solidity project to demonstrate **Uniswap V2 token swaps** and **liquidity add/remove** flows, with forked test support and deployment scripts using Foundry.

---

## Features

- **Swap Demo (`UniswapV2SwapDemo`)**  
  - Single-hop and multi-hop token swaps  
  - Exact in / exact out swaps  
  - Supports fee-on-transfer tokens (special case, skipped in tests)  
  - Emits `SwapExecuted` events for monitoring  

- **Liquidity Demo (`UniswapV2AddRemoveLiquidityDemo`)**  
  - Add liquidity to Uniswap V2 pools  
  - Remove liquidity from pools  
  - Handles edge cases: insufficient liquidity, deadline exceeded  
  - Emits `LiquidityAdded` and `LiquidityRemoved` events  

- **Optimal One-Side Supply Demo (`UniswapV2OptimalOneSideSupply`)**  
  - Calculates optimal token amount for one-sided liquidity provision  
  - Minimizes impermanent loss by balancing token amounts  
  - Supports adding liquidity with a single token input  

---

## Project Structure

```
src/
  UniswapV2SwapDemo.sol
  UniswapV2AddRemoveLiquidityDemo.sol
  UniswapV2OptimalOneSideSupply.sol
test/fork/
  UniswapV2SwapDemo.t.sol
  UniswapV2AddRemoveLiquidityDemo.t.sol
  UniswapV2OptimalOneSideSupply.t.sol
script/
  UniswapV2SwapDemo.s.sol
  UniswapV2AddRemoveLiquidityDemo.s.sol
  UniswapV2OptimalOneSideSupply.s.sol
```

- `src/` → Solidity contracts  
- `test/fork/` → Foundry tests (using forked Sepolia chain)  
- `script/` → Deployment & interaction scripts (using `vm.startBroadcast`)  

---

## Build / Compile

1. Install Foundry (if not already):

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Compile contracts:

```bash
forge build
```

---

## Test

The tests run **against a forked Sepolia environment**:

```bash
# make sure .env contains SEPOLIA_RPC_URL, USER, TOKENS, UNIX_TIME,ROUTER, FACTORY
forge test -vvvv
```

- have `vm.createSelectFork` in test contract so there is no need for `--fork-url`
- have `vm.startPrank` in test contract so there is no need for `--private-key`
---

## Scripts

Use the scripts to **deploy contracts and interact on fork or Sepolia**:

```bash
# Swap Demo script
forge script script/UniswapV2SwapDemo.s.sol:UniswapV2SwapDemoScript \
  --broadcast -vvvv

# Liquidity Demo script
forge script script/UniswapV2AddRemoveLiquidityDemo.s.sol:UniswapV2AddRemoveLiquidityDemoScript \
  --broadcast -vvvv

# Optimal One-Side Supply Demo script
forge script script/UniswapV2OptimalOneSideSupply.s.sol:UniswapV2OptimalOneSideSupplyScript \
  --broadcast -vvvv
```

- have `vm.createSelectFork` in script contract so there is no need for --fork-url
- have `vm.startPrank` in script contract so there is no need for --private-key
- `--broadcast` → sends real transactions if targeting live/testnet  
- `-vvvv` → verbose output, useful for debugging amounts and balances  

**Notes:**  
- Scripts automatically create pair if not exist, approve tokens, add/remove liquidity, and log results.  
- Use `.env` to provide: `SEPOLIA_RPC_URL`, `PRIVATE_KEY`, `ROUTER`, `FACTORY`, `TOKENA/B/C`, `USER`, `UNIX_TIME`.

---
## Deployed Contracts

- `tokenA:0x55d1632087b123E0988CE2c718ba30A5502Eb697`
- `tokenB:0x5ce6290A3923f82A302f2fdEfFbB92Ed8eA2D023`
- `tokenC:0x7517CC51e2d5b3bAdd68B3399C64FbEAEaaCb33C`
- `swapper:0x3dcdf52d388Ae5bb69553E29e5eB40FCBcaf9478`
- `liquidityProvider:0xA8C9648c980251d4F09f0CAF6576FBc715acd79E`
- `zapper:0xc452eF8E8185D8f596B21B67b6940400ccd00B5E`

---
## Disclaimer

- For **learning/demo purposes only**.  
- Not intended for production or real user funds.  
