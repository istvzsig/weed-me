// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SeedNFT is ERC721, Ownable {
    uint256 public nextId;

    constructor(
        address initialOwner
    ) ERC721("Weed Farm Seed", "SEED") Ownable(initialOwner) {}

    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = ++nextId;
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
