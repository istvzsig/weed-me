# 🌱 Weed Farm NFT Game

Weed Farm is a blockchain-based NFT farming game where players plant seeds, grow them into NFT plants, and earn in-game currency (WEED) as rewards. The game is designed for fun, experimentation, and testing economic models locally or on testnets.

---

## Table of Contents

- [Game Concept](#game-concept)
- [Core Gameplay Loop](#core-gameplay-loop)
- [In-Game Economy](#in-game-economy)
- [Business Model](#business-model)
- [Developer Setup](#developer-setup)
- [Future Enhancements](#future-enhancements)

---

## Game Concept

Players grow NFT plants in a digital farm using the in-game currency WEED. Each plant is represented as an NFT, which can be harvested for rewards and potentially traded. The game uses a simple play-to-earn loop to keep players engaged and allows experimentation with tokenomics and NFT mechanics.

---

## Core Gameplay Loop

1. **Connect Wallet**: Players connect their Ethereum wallet (e.g., MetaMask).
2. **Acquire WEED**: Players start with free WEED tokens (faucet) or purchase with ETH (optional for monetization).
3. **Plant Seeds**: Spend WEED to mint NFT plants. Players can choose different seed types with varying growth times and rewards.
4. **Grow**: Plants take some time to mature. Short grow times are ideal for testing, longer grow times for mainnet gameplay.
5. **Harvest**: Once matured, plants can be harvested to earn more WEED tokens.
6. **Repeat / Trade**: Players can reinvest their WEED into more seeds or trade NFT plants on a marketplace (optional).

---

## In-Game Economy

- **WEED Tokens (ERC20)**:

  - Currency used for planting seeds and earning rewards.
  - Can be earned from harvesting plants.
  - Optionally purchased with ETH for premium gameplay.

- **NFT Plants (ERC721)**:

  - Represent individual plants grown by the player.
  - Different types of seeds yield different rewards.
  - Can be traded or collected for achievements.

- **Balance and Rewards**:
  - Players earn WEED proportional to the type and number of plants harvested.
  - Optional rare plants or seasonal seeds increase rewards.

---

## Business Model

1. **Play-to-Earn (P2E)**: Players earn tokens by actively playing the game.
2. **Free-to-Play (F2P)**: New players start with a WEED faucet to encourage experimentation without spending money.
3. **Optional Premium Purchases**: Players can buy WEED with ETH to speed up growth or acquire rare seeds.
4. **NFT Marketplace**: Players can trade plants, seeds, or harvested NFTs. The platform can take a small transaction fee for monetization.
5. **Economy Controls**:
   - Rare seeds or plants act as scarcity mechanics.
   - Token sinks (e.g., burning WEED to mint rare NFTs) prevent inflation.
   - Seasonal or limited edition plants create engagement and hype.

This model balances **player engagement, rewards, and potential revenue streams** while keeping the game accessible for testing and development.

---

## Developer Setup

1. **Start Hardhat Node**: Local blockchain with pre-funded test accounts.
   ```bash
   npx hardhat node
   ```

````

2. **Deploy Contracts**: Deploy WeedToken, PlantNFT, and FarmGame contracts. Transfer ownership to FarmGame for full gameplay.

3. **Configure Frontend**: Set contract addresses in `.env` for React frontend.

4. **Play the Game Locally**:

   - Connect wallet via MetaMask.
   - Acquire WEED tokens (faucet).
   - Plant seeds, wait for growth, and harvest rewards.
   - Repeat and test economy dynamics.

---

## Future Enhancements

- Rare/seasonal plant types with higher rewards.
- Plant breeding mechanics for NFT upgrades.
- Real ETH or stablecoin purchases of WEED for monetization.
- Marketplace integration for trading NFTs and harvested tokens.
- Analytics for balancing rewards and growth times.

---

## Notes

- Designed for **local development and testnet experimentation**.
- Hardhat test accounts come pre-funded with 1000 ETH to simplify testing.
- Grow times are short (minutes) for development but can be adjusted for production.

---

🌱 Enjoy growing your NFT farm and experimenting with play-to-earn mechanics!

```

---

This version focuses entirely on **gameplay flow, economy, and monetization strategy**, while giving developers a **simple local dev setup**.

If you want, I can also create a **diagram/visual map of the game economy** (NFTs, WEED token flow, rewards, and optional ETH purchases) to make it easier for devs to follow.

Do you want me to do that next?
```
