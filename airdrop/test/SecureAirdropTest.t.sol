// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/SecureAirdrop.sol";
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

contract SecureAirdropTest is Test {
    using ECDSA for bytes32;

    ERC20Mock token;
    SecureAirdrop airdrop;
    address signer;
    address user;

    function setUp() public {
        signer = vm.addr(1);
        user = vm.addr(2);

        token = new ERC20Mock("Test Token", "TST", address(this), 10000 ether);
        airdrop = new SecureAirdrop(address(token), signer);

        token.transfer(address(airdrop), 1000 ether);
    }

    function testValidClaim() public {
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(user, amount, nonce))
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        airdrop.claimTokens(amount, nonce, signature);
        assertEq(token.balanceOf(user), amount);
        assertEq(airdrop.nonces(user), nonce + 1);
    }

    function testReplayAttackFails() public {
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(user, amount, nonce))
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        airdrop.claimTokens(amount, nonce, signature);
        assertEq(token.balanceOf(user), amount);
        assertEq(airdrop.nonces(user), nonce + 1);

        vm.expectRevert("Invalid nonce");
        vm.prank(user);
        airdrop.claimTokens(amount, nonce, signature);
    }

    function testInvalidSignatureFails() public {
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(user, amount, nonce))
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, messageHash); // Signed by a different address
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Invalid signature");
        vm.prank(user);
        airdrop.claimTokens(amount, nonce, signature);
    }

    function testDifferentNonce() public {
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(user, amount, nonce))
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        airdrop.claimTokens(amount, nonce, signature);
        assertEq(token.balanceOf(user), amount);
        assertEq(airdrop.nonces(user), nonce + 1);

        // Attempt to use a different nonce
        nonce = 1;
        messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32", 
            keccak256(abi.encodePacked(user, amount, nonce))
        ));
        (v, r, s) = vm.sign(1, messageHash);
        signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        airdrop.claimTokens(amount, nonce, signature);
        assertEq(token.balanceOf(user), 2 * amount);
        assertEq(airdrop.nonces(user), nonce + 1);
    }
}
