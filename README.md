# Weed Me - web3 game demo

- A playable farming loop (plant → grow → harvest)
- On-chain assets (NFT plants + ERC20 token)
- Wallet connection
- Play-to-Earn logic (harvest → token reward)
- Clean, readable code & repo structure

## Final MVP Scope

### What you WILL build

- Single-player farm
- 2 plant types
- Time-based growth
- ERC20 reward token
- ERC721 plants
- Minimal UI
- Local + testnet deploy

### What you will NOT build

- Marketplace
- Cooperatives
- Events
- Animations
- Real money trading

## Tech Stack (Fast & Hire-Friendly)

### Frontend

- Next.js
- ethers.js
- Tailwind (optional)
- Wallet: MetaMask

### Smart Contracts

- Solidity
- Hardhat
- Contracts:
  - FarmGame.sol
  - WeedToken.sol (ERC20)
  - PlantNFT.sol (ERC721)

### Network

Polygon Mumbai or Base Sepolia

## Core Game Design (Minimal but Legit)

### Plant Types (hardcoded)

```javascript
PlantType {
  id: 0 | 1
  name: "OG Kush" | "Blue Dream"
  growTime: 5 min | 10 min
  reward: 10 | 25 WEED
}
```

### Gameplay Loop (1 Smart Contract)

**1. Plant Seed**

```sol
function plant(uint8 plantType) external;
```

- Mints an NFT
- Stores:
  - owner
  - plantedAt
  - plantType
  - harvested = false

**2. Grow (Passive)**

- No action
- Growth = block.timestamp - plantedAt

**3. Harvest**

```sol
function harvest(uint256 tokenId) external;
```

Requirements:

- Caller owns NFT
- now >= plantedAt + growTime
- Not harvested yet

Result:

- Mint WEED tokens
- Mark NFT as harvested

### Tokenomics (Simple & Defensible)

**WeedToken (ERC20)**

- Minted **only on harvest**
- No max supply (acceptable for MVP)
- Demonstrates:
  - Emissions logic
  - Reward mechanism
  - Anti-double harvest

## Smart Contract Structure

### FarmGame.sol (Main Logic)

```sol
struct Plant {
  uint8 plantType;
  uint256 plantedAt;
  bool harvested;
}
mapping(uint256 => Plant) public plants;
```

Responsibilities:

- Mint plant NFT
- Track growth
- Mint reward tokens

### PlantNFT.sol

- ERC721
- tokenURI() returns JSON metadata:

```sol
{
  "name": "OG Kush",
  "attributes": [
    { "trait_type": "Grow Time", "value": "5 min" }
  ]
}
```

### WeedToken.sol

- ERC20
- mint(address to, uint amount)
- Only callable by FarmGame

### Frontend Pages (Only 2)

```javscript
/
```

**Farm Dashboard**

- Connect Wallet
- Show owned plants
- Show WEED balance
- Buttons:
  - Plant OG Kush
  - Plant Blue Dream
  - Harvest (if ready)

```javscript
/admin (Optional)
```

- Show contract addresses
- Network info

## What Recruiters Will Actually Care About

- Clear system architecture
- Tokenomics explanation
- Security considerations
- Tradeoffs & future improvements

That sentence alone scores points.

### Optional Power Move (If Time Left)

```sol
event Harvested(address player, uint tokenId, uint reward);
```

Show it in frontend -> proves Web3 event handling.

### Frontend Start ( Local Dev )

Hardhat with node

```bash
npx hardhat node
```

Deploy on localhost network

```bash
npx hardhat run scripts/deploy.ts --network localhost
```

Run this command from project root:

```bash
DEBUG=* npm --prefix ./frontend run dev
```

Or use starter script commands:

```bash
chmod +x ./start.sh
./start.sh
```
