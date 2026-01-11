"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";

import FarmGameABI from "../abi/FarmGame.sol/FarmGame.json";
import WeedTokenABI from "../abi/WeedToken.sol/WeedToken.json";
import PlantNFTABI from "../abi/PlantNFT.sol/PlantNFT.json";

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
  // Connect Wallet
  // ----------------------
  async function connectWallet() {
    if (!window.ethereum) return alert("Install MetaMask");
    const provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts", []);
    setAccount(accounts[0]);

    const signer = await provider.getSigner();
    const farmContract = new ethers.Contract(
      FARM_GAME_ADDRESS,
      FarmGameABI.abi,
      signer
    );
    setFarm(farmContract);
  }

  // ----------------------
  // Load WEED Balance
  // ----------------------
  async function loadBalance() {
    if (!account) return;
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const weed = new ethers.Contract(
      WEED_TOKEN_ADDRESS,
      WeedTokenABI.abi,
      signer
    );

    try {
      const address = await signer.getAddress();
      const balance = await weed.balanceOf(address);
      setWeedBalance(ethers.formatEther(balance));
    } catch (err) {
      console.error("Error reading WEED balance:", err);
      setWeedBalance("0");
    }
  }

  // ----------------------
  // Load Owned Plants
  // ----------------------
  async function loadPlants() {
    if (!account || !farm) return;
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const nft = new ethers.Contract(PLANT_NFT_ADDRESS, PlantNFTABI.abi, signer);

    const address = await signer.getAddress();
    const balance = Number(await nft.balanceOf(address));
    const owned: number[] = [];

    for (let i = 0; i < balance; i++) {
      const tokenId = await nft.tokenOfOwnerByIndex(address, i);
      owned.push(Number(tokenId));
    }

    setPlants(owned);

    const status: { [id: number]: boolean } = {};
    for (const id of owned) {
      status[id] = await farm.isReadyToHarvest(id);
    }
    setReady(status);
  }

  // ----------------------
  // Plant
  // ----------------------
  async function plant(type: number) {
    if (!farm) return;
    const tx = await farm.plant(type);
    await tx.wait();
    await loadPlants();
    await loadBalance();
  }

  // ----------------------
  // Harvest
  // ----------------------
  async function harvest(id: number) {
    if (!farm) return;
    const tx = await farm.harvest(id);
    await tx.wait();
    await loadPlants();
    await loadBalance();
  }

  // Reload data whenever account or farm changes
  useEffect(() => {
    if (!account || !farm) return;
    (async () => {
      // await loadPlants();
      // await loadBalance();
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
          <button onClick={() => plant(0)}>Plant OG Kush</button>
          <button onClick={() => plant(1)}>Plant Blue Dream</button>

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
