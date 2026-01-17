// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlantNFT is ERC721Enumerable, Ownable {
    uint256 public nextTokenId;

    constructor(
        address initialOwner
    ) ERC721("Weed Plant", "PLANT") Ownable(initialOwner) {}

    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }
}
