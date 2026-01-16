// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./WeedToken.sol";
import "./PlantNFT.sol";

contract FarmGame {
    WeedToken public weedToken;
    PlantNFT public plantNFT;

    enum PlantType {
        OG_KUSH,
        BLUE_DREAM
    }

    struct Plant {
        PlantType plantType;
        uint256 plantedAt;
        bool harvested;
    }

    // tokenId => Plant data
    mapping(uint256 => Plant) public plants;

    event Planted(address indexed player, uint256 tokenId, PlantType plantType);
    event Harvested(address indexed player, uint256 tokenId, uint256 reward);

    constructor(address _weedToken, address _plantNFT) {
        weedToken = WeedToken(_weedToken);
        plantNFT = PlantNFT(_plantNFT);
    }

    // -----------------------------
    // Gameplay
    // -----------------------------

    function plant(PlantType plantType) external {
        uint256 tokenId = plantNFT.mint(msg.sender);

        plants[tokenId] = Plant({
            plantType: plantType,
            plantedAt: block.timestamp,
            harvested: false
        });

        emit Planted(msg.sender, tokenId, plantType);
    }

    function harvest(uint256 tokenId) external {
        require(plantNFT.ownerOf(tokenId) == msg.sender, "Not owner");

        Plant storage plantData = plants[tokenId];
        require(!plantData.harvested, "Already harvested");
        require(isReadyToHarvest(tokenId), "Not ready");

        uint256 reward = getReward(plantData.plantType);

        plantData.harvested = true;
        weedToken.mint(msg.sender, reward);

        emit Harvested(msg.sender, tokenId, reward);
    }

    function buyWeed() external {
        weedToken.mint(msg.sender, 100 ether);
    }

    // -----------------------------
    // View Helpers
    // -----------------------------

    function isReadyToHarvest(uint256 tokenId) public view returns (bool) {
        Plant memory plantData = plants[tokenId];
        uint256 growTime = getGrowTime(plantData.plantType);
        return block.timestamp >= plantData.plantedAt + growTime;
    }

    function getGrowTime(PlantType plantType) public pure returns (uint256) {
        if (plantType == PlantType.OG_KUSH) {
            return 5 minutes;
        } else {
            return 10 minutes;
        }
    }

    function getReward(PlantType plantType) public pure returns (uint256) {
        if (plantType == PlantType.OG_KUSH) {
            return 10 * 1e18;
        } else {
            return 25 * 1e18;
        }
    }
}
