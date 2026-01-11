"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";

import FarmGameABI from "../abi/FarmGame.sol/FarmGame.json";
import WeedTokenABI from "../abi/WeedToken.sol/WeedToken.json";
import PlantNFTABI from "../abi/PlantNFT.sol/PlantNFT.json";

// TODO: Replace these with deployed addresses
const FARM_GAME_ADDRESS = "PASTE_FARMGAME_ADDRESS_HERE";
const WEED_TOKEN_ADDRESS = "PASTE_WEEDTOKEN_ADDRESS_HERE";
const PLANT_NFT_ADDRESS = "PASTE_PLANTNFT_ADDRESS_HERE";

export default function Home() {
  const [account, setAccount] = useState<string | null>(null);
  const [farm, setFarm] = useState<ethers.Contract | null>(null);
  const [plants, setPlants] = useState<number[]>([]);
  const [weedBalance, setWeedBalance] = useState("0");
  const [ready, setReady] = useState<{ [id: number]: boolean }>({});

  // ----------------------
  // Wallet
  // ----------------------
  async function connectWallet() {
    if (!window.ethereum) return alert("Install MetaMask");
    const provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts", []);
    setAccount(accounts[0]);
  }

  // ----------------------
  // Setup Farm Contract
  // ----------------------
  useEffect(() => {
    if (!account) return;

    const provider = new ethers.BrowserProvider(window.ethereum);
    provider.getSigner().then((signer) => {
      const farmContract = new ethers.Contract(
        FARM_GAME_ADDRESS,
        FarmGameABI.abi,
        signer
      );
      setFarm(farmContract);
    });
  }, [account]);

  // ----------------------
  // Load WEED Balance
  // ----------------------
  async function loadBalance() {
    if (!account) return;
    const provider = new ethers.BrowserProvider(window.ethereum);
    const weed = new ethers.Contract(
      WEED_TOKEN_ADDRESS,
      WeedTokenABI.abi,
      provider
    );
    const balance = await weed.balanceOf(account);
    setWeedBalance(ethers.formatEther(balance));
  }

  // ----------------------
  // Load Owned Plants
  // ----------------------
  async function loadPlants() {
    if (!account) return;
    const provider = new ethers.BrowserProvider(window.ethereum);
    const nft = new ethers.Contract(
      PLANT_NFT_ADDRESS,
      PlantNFTABI.abi,
      provider
    );

    const balance = await nft.balanceOf(account);
    const owned: number[] = [];
    for (let i = 0; i < balance; i++) {
      const tokenId = await nft.tokenOfOwnerByIndex(account, i);
      owned.push(Number(tokenId));
    }
    setPlants(owned);

    // Check which plants are ready
    if (farm) {
      const status: { [id: number]: boolean } = {};
      for (const id of owned) {
        status[id] = await farm.isReadyToHarvest(id);
      }
      setReady(status);
    }
  }

  // ----------------------
  // Plant
  // ----------------------
  async function plantOG() {
    if (!farm) return;
    await farm.plant(0);
    setTimeout(loadPlants, 1000);
    setTimeout(loadBalance, 1000);
  }

  async function plantBlue() {
    if (!farm) return;
    await farm.plant(1);
    setTimeout(loadPlants, 1000);
    setTimeout(loadBalance, 1000);
  }

  // ----------------------
  // Harvest
  // ----------------------
  async function harvest(id: number) {
    if (!farm) return;
    await farm.harvest(id);
    setTimeout(loadPlants, 1000);
    setTimeout(loadBalance, 1000);
  }

  // Reload data whenever account or farm changes
  useEffect(() => {
    if (!account || !farm) return;
    (async () => {
      await loadPlants();
      await loadBalance();
    })();
  }, [account, farm]);

  // ----------------------
  // Render UI
  // ----------------------
  return (
    <main style={{ padding: 40 }}>
      <h1>🌱 Weed Farm</h1>

      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <>
          <p>Connected: {account}</p>
          <p>WEED Balance: {weedBalance}</p>

          <h2>🌱 Plant Seeds</h2>
          <button onClick={plantOG}>Plant OG Kush</button>
          <button onClick={plantBlue}>Plant Blue Dream</button>

          <h2>Your Plants</h2>
          {plants.length === 0 && <p>No plants yet</p>}
          {plants.map((id) => (
            <div key={id} style={{ margin: "10px 0" }}>
              <span>
                Plant #{id} — {ready[id] ? "✅ Ready" : "⏳ Growing"}
              </span>
              {ready[id] && (
                <button style={{ marginLeft: 10 }} onClick={() => harvest(id)}>
                  Harvest
                </button>
              )}
            </div>
          ))}
        </>
      )}
    </main>
  );
}
