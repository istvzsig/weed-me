// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeedToken is ERC20, Ownable {
    constructor()
        ERC20("Weed Token", "WEED")
        Ownable(msg.sender)
    {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Transfer(address(0), to, amount);  // ERC20 Mint event
    }

    function burnFrom(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        emit Transfer(from, address(0), amount);  // ERC20 Burn event
    }
}
