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
        uint64 price;
    }

    uint256 public constant FAUCET_AMOUNT = 20 ether;
    uint256 public constant FAUCET_COOLDOWN = 5 minutes;

    mapping(uint256 => Plant) public plants;
    mapping(address => uint256[]) private _playerPlants;
    mapping(address => uint256) public lastFaucetClaim;

    event Planted(address indexed player, uint256 tokenId, PlantType plantType);
    event Harvested(address indexed player, uint256 tokenId, uint256 reward);
    event FaucetClaimed(address indexed player, uint256 amount);

    constructor(address _weedToken, address _plantNFT) {
        weedToken = WeedToken(_weedToken);
        plantNFT = PlantNFT(_plantNFT);
    }

    // -----------------------------
    // Gameplay
    // -----------------------------

    function faucet() external {
        require(block.chainid != 1, "Faucet disabled on mainnet");
        require(
            block.timestamp >= lastFaucetClaim[msg.sender] + FAUCET_COOLDOWN,
            "Faucet cooldown active"
        );

        lastFaucetClaim[msg.sender] = block.timestamp;
        weedToken.mint(msg.sender, FAUCET_AMOUNT);

        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }

    function plant(PlantType plantType) external {
        uint256 price = getPlantPrice(plantType);

        weedToken.transferFrom(msg.sender, address(this), price);

        uint256 tokenId = plantNFT.mint(msg.sender);

        plants[tokenId] = Plant({
            plantType: plantType,
            plantedAt: block.timestamp,
            harvested: false,
            price: uint64(price)
        });

        _playerPlants[msg.sender].push(tokenId);

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

    function buyWeed() external payable {
        uint256 pricePerToken = 0.001 ether;
        require(msg.value >= pricePerToken, "Send enough ETH");

        uint256 amountToMint = (msg.value * 1 ether) / pricePerToken;
        uint256 cost = (amountToMint * pricePerToken) / 1 ether;

        // Refund excess ETH
        uint256 refund = msg.value - cost;
        if (refund > 0) {
            (bool success, ) = msg.sender.call{value: refund}("");
            require(success, "ETH refund failed");
        }

        weedToken.mint(msg.sender, amountToMint);
    }

    // -----------------------------
    // View Helpers
    // -----------------------------

    function isReadyToHarvest(uint256 tokenId) public view returns (bool) {
        Plant memory plantData = plants[tokenId];

        if (plantData.plantedAt == 0 || plantData.harvested) {
            return false;
        }

        uint256 growTime = getGrowTime(plantData.plantType);
        return block.timestamp >= plantData.plantedAt + growTime;
    }

    function getPlantPrice(PlantType plantType) public pure returns (uint256) {
        if (plantType == PlantType.OG_KUSH) {
            return 5 ether;
        } else {
            return 8 ether;
        }
    }

    function getGrowTime(PlantType plantType) public pure returns (uint256) {
        if (plantType == PlantType.OG_KUSH) {
            return 1 minutes;
        } else {
            return 2 minutes;
        }
    }

    function getReward(PlantType plantType) public pure returns (uint256) {
        if (plantType == PlantType.OG_KUSH) {
            return 10 * 1e18;
        } else {
            return 25 * 1e18;
        }
    }

    function getPlayerPlants(
        address player
    ) external view returns (uint256[] memory) {
        return _playerPlants[player];
    }
}
