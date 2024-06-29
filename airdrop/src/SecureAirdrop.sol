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
