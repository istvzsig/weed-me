// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./WeedToken.sol";
import "./PlantNFT.sol";
import "./SeedNFT.sol";

contract FarmGame is Ownable {
    WeedToken public weedToken;
    SeedNFT public seedNFT;
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

    uint256 public constant BASIC_SEED_PRICE = 0.002 ether;
    uint256 public FAUCET_COOLDOWN = 5 minutes;
    uint256 public FAUCET_AMOUNT = 20 ether;
    uint256 public dailyCap;
    bool public faucetEnabled = false;
    address public treasury;

    mapping(uint256 => Plant) public plants;
    mapping(address => uint256) public seeds;
    mapping(address => uint256[]) private _playerPlants;
    mapping(address => uint256) public lastFaucetClaim;

    event Planted(address indexed player, uint256 tokenId, PlantType plantType);
    event Harvested(address indexed player, uint256 tokenId, uint256 reward);
    event FaucetClaimed(address indexed player, uint256 amount);
    event SeedBought(
        address indexed buyer,
        uint256 indexed seedId,
        uint256 price
    );

    constructor(
        address _weedToken,
        address _plantNFT,
        address _seedNFT,
        bool _faucetEnabled,
        address _treasury
    ) Ownable(msg.sender) {
        weedToken = WeedToken(_weedToken);
        plantNFT = PlantNFT(_plantNFT);
        seedNFT = SeedNFT(_seedNFT);
        faucetEnabled = _faucetEnabled;
        treasury = _treasury;
    }

    // -----------------------------
    // Admin
    // -----------------------------

    function setFaucetEnabled(bool enabled) external onlyOwner {
        faucetEnabled = enabled;
    }

    function setFaucetAmount(uint256 amount) external onlyOwner {
        FAUCET_AMOUNT = amount * 1 ether;
    }

    function setFaucetCooldown(uint256 cooldownInMinutes) external onlyOwner {
        FAUCET_COOLDOWN = cooldownInMinutes * 1 minutes;
    }

    function setDailyCap(uint256 cap) external onlyOwner {
        dailyCap = cap;
    }

    function withdraw() external onlyOwner {
        (bool ok, ) = treasury.call{value: address(this).balance}("");
        require(ok, "Withdraw failed");
    }

    // -----------------------------
    // Gameplay
    // -----------------------------

    function faucet() external {
        require(faucetEnabled, "Faucet disabled");
        require(
            block.timestamp >= lastFaucetClaim[msg.sender] + FAUCET_COOLDOWN,
            "Faucet cooldown active"
        );

        lastFaucetClaim[msg.sender] = block.timestamp;
        weedToken.mint(msg.sender, FAUCET_AMOUNT);
        emit FaucetClaimed(msg.sender, FAUCET_AMOUNT);
    }

    function plant(uint256 seedId, PlantType plantType) external {
        // must own seed
        require(seedNFT.ownerOf(seedId) == msg.sender, "Not seed owner");

        // burn seed (FarmGame must be SeedNFT owner)
        seedNFT.burn(seedId);

        // OPTIONAL: also charge WEED as a sink (good for economy)
        uint256 weedPrice = getPlantPrice(plantType);
        weedToken.transferFrom(msg.sender, address(this), weedPrice);

        uint256 tokenId = plantNFT.mint(msg.sender);

        plants[tokenId] = Plant({
            plantType: plantType,
            plantedAt: block.timestamp,
            harvested: false,
            price: uint64(weedPrice)
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

    function buySeeds(uint256 amount) external payable {
        uint256 pricePerSeed = 0.002 ether;
        require(msg.value == pricePerSeed * amount, "Wrong ETH");
        seeds[msg.sender] += amount;
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
    // Helpers
    // -----------------------------

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

    function isReadyToHarvest(uint256 tokenId) public view returns (bool) {
        Plant memory plantData = plants[tokenId];

        if (plantData.plantedAt == 0 || plantData.harvested) {
            return false;
        }

        uint256 growTime = getGrowTime(plantData.plantType);
        return block.timestamp >= plantData.plantedAt + growTime;
    }
}
