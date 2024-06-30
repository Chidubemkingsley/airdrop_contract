## solve ethernaut Dex & Dex2 challenge and write a full report about it with POC included.

 - Aim of the Dex challenge is to attack the DEX contract in Dex.sol and drain the funds there by using the strategy of price manipulation. 

 -- The `swap()` and getSwapPrice functions allow token swaps, checks balances, calculates swap amounts, and transfers tokens, but is vulnerable to price manipulation.
 --Below is the code for the swap performed between token1 and token2

```
function swap(address from, address to, uint amount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint swapAmount = getSwapPrice(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}
```

- It checks token validity and user balance, calculates the swap amount using `getSwapPrice()`, and completes the swap with two `transferFrom` calls.

- The `getSwapPrice()` function calculates the swap amount:
```solidity
return((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
```
- This follows the constant function market maker equation `x * y = k`. However, due to Solidity's lack of decimal support, fractional quotients are rounded down, creating an opportunity for price manipulation.

- By repeatedly swapping our total balance between `token1` and `token2`, we can exponentially grow our balance and eventually drain the DEX of its tokens. The critical point is reaching 65 tokens, which allows us to drain the entire balance of the respective token.
This table outlines the process of manipulating the DEX (Decentralized Exchange) by repeatedly swapping tokens to increase the user's token balance and drain the DEX's token reserves. Here is a step-by-step explanation of each swap:

1. **Initial State:**
   - **DEX:** 100 tokens of `token1` and 100 tokens of `token2`.
   - **User:** 10 tokens of `token1` and 10 tokens of `token2`.

2. **First Swap:**
   - **Action:** Swap 10 tokens of `token1` for `token2`.
   - **DEX:** Receives 10 `token1` (new balance: 110 `token1`) and gives out 10 `token2` (new balance: 90 `token2`).
   - **User:** Gives 10 `token1` (new balance: 0 `token1`) and receives 20 `token2` (new balance: 20 `token2`).

3. **Second Swap:**
   - **Action:** Swap 20 tokens of `token2` for `token1`.
   - **DEX:** Receives 20 `token2` (new balance: 110 `token2`) and gives out 24 `token1` (new balance: 86 `token1`).
   - **User:** Gives 20 `token2` (new balance: 0 `token2`) and receives 24 `token1` (new balance: 24 `token1`).

4. **Third Swap:**
   - **Action:** Swap 24 tokens of `token1` for `token2`.
   - **DEX:** Receives 24 `token1` (new balance: 110 `token1`) and gives out 30 `token2` (new balance: 80 `token2`).
   - **User:** Gives 24 `token1` (new balance: 0 `token1`) and receives 30 `token2` (new balance: 30 `token2`).

5. **Fourth Swap:**
   - **Action:** Swap 30 tokens of `token2` for `token1`.
   - **DEX:** Receives 30 `token2` (new balance: 110 `token2`) and gives out 41 `token1` (new balance: 69 `token1`).
   - **User:** Gives 30 `token2` (new balance: 0 `token2`) and receives 41 `token1` (new balance: 41 `token1`).

6. **Fifth Swap:**
   - **Action:** Swap 41 tokens of `token1` for `token2`.
   - **DEX:** Receives 41 `token1` (new balance: 110 `token1`) and gives out 45 `token2` (new balance: 45 `token2`).
   - **User:** Gives 41 `token1` (new balance: 0 `token1`) and receives 65 `token2` (new balance: 65 `token2`).

7. **Final Swap:**
   - **Action:** Swap 65 tokens of `token2` for `token1`.
   - **DEX:** Receives 65 `token2` (new balance: 90 `token2`) and gives out 110 `token1` (new balance: 0 `token1`).
   - **User:** Gives 65 `token2` (new balance: 20 `token2`) and receives 110 `token1` (new balance: 110 `token1`).

**Outcome:**
- The user ends up with 110 tokens of `token1` and 20 tokens of `token2`.
- The DEX is left with 0 tokens of `token1` and 90 tokens of `token2`.

Through strategic swaps, the user has drained all `token1` from the DEX by exploiting the constant function market maker equation and Solidity's integer division.

To execute the hack:
1. Deploy `AttackDex` with the instance address.
2. Deploy the IERC20 interface for `token1` and `token2`.
3. Deploy the IDEX interface to get token addresses.
4. Approve `AttackDex` for a large amount.
5. Call the `hack()` function to drain `token1` from the DEX.
