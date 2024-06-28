# VulnerableAirdrop Contract

## Overview

The `VulnerableAirdrop` contract allows users to claim tokens by providing a valid signature from a designated signer. However, this contract contains a critical vulnerability that allows signature replay attacks, enabling users to claim tokens multiple times using the same valid signature.

This repository includes the vulnerable contract, a secure version of the contract with the replay attack mitigation, and tests demonstrating the vulnerability and its exploit using Foundry.

## Files

- `src/VulnerableAirdrop.sol`: The vulnerable airdrop contract.
- `src/SecureAirdrop.sol`: The secure version of the airdrop contract with nonce-based replay protection.
- `test/VulnerableAirdropTest.t.sol`: Test file demonstrating the exploit of the signature replay vulnerability.
- `test/SecureAirdropTest.t.sol`: Test file demonstrating the fixed contract's resistance to signature replay attacks.
- `src/ERC20Mock.sol`: A mock ERC20 token used for testing.

## Vulnerability Details

### Vulnerability: Signature Replay Attack

**Severity**: High

**Description**: The `VulnerableAirdrop` contract does not keep track of used signatures, allowing attackers to reuse a valid signature to claim tokens multiple times.

### Impact

The signature replay vulnerability allows malicious users to claim tokens multiple times with the same signature, leading to significant financial losses for the contract owner and depleting the contract's token balance.

### Recommendation

To prevent signature replay attacks, it is crucial to keep track of used signatures or nonces. The `SecureAirdrop` contract implements this solution by including a nonce in the signed message and storing each user's nonce.

## Getting Started

### Prerequisites

Ensure you have Foundry installed. If not, you can install it by following the instructions in the [Foundry Book](https://book.getfoundry.sh/getting-started/installation.html).

### Installation

Clone the repository:

```bash
git clone https://github.com/Chidubemkingsley/airdrop_contract.git
cd VulnerableAirdrop
```

Install dependencies:

```bash
forge install
```

### Running the Tests

To run the tests, use the following command:

```bash
forge test
```

This command will execute the tests in the `test/VulnerableAirdropTest.t.sol` and `test/SecureAirdropTest.t.sol` files, demonstrating the vulnerability and its fix.


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
