"use client";

import { useEffect, useState } from "react";
import Web3 from "web3";
import type { Contract } from "web3-eth-contract";

import FarmGameABI from "../abi/FarmGame.sol/FarmGame.json";
import WeedTokenABI from "../abi/WeedToken.sol/WeedToken.json";
import PlantNFTABI from "../abi/PlantNFT.sol/PlantNFT.json";

const WEED_TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const PLANT_NFT_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const FARM_GAME_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

/* ----------------------
   Logger helper
---------------------- */
function log(scope: string, message: string, data?: any) {
  console.log(
    `%c[${scope}]`,
    "color:#22c55e;font-weight:bold",
    message,
    data ?? ""
  );
}

export default function Home() {
  const [web3, setWeb3] = useState<Web3 | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [farm, setFarm] = useState<Contract | null>(null);
  const [loading, setLoading] = useState(false);
  const [plants, setPlants] = useState<number[]>([]);
  const [weedBalance, setWeedBalance] = useState<string>("0");
  const [ready, setReady] = useState<Record<number, boolean>>({});

  /* ----------------------
     Init Web3
  ---------------------- */
  useEffect(() => {
    if ((window as any).ethereum) {
      log("WEB3", "Initializing Web3 provider");
      const web3Instance = new Web3((window as any).ethereum);
      setWeb3(web3Instance);
    } else {
      log("WEB3", "No wallet detected");
      alert("Please install MetaMask");
    }
  }, []);

  /* ----------------------
     Connect Wallet
  ---------------------- */
  async function connectWallet() {
    if (!web3) return;

    log("WALLET", "Requesting accounts");
    const accounts = await web3.eth.requestAccounts();

    if (!accounts.length) {
      log("WALLET", "No accounts returned");
      return;
    }

    const acc = accounts[0];
    setAccount(acc);
    log("WALLET", "Connected", acc);

    const farmContract = new web3.eth.Contract(
      FarmGameABI.abi as any,
      FARM_GAME_ADDRESS
    );
    setFarm(farmContract);
    log("CONTRACT", "FarmGame loaded", FARM_GAME_ADDRESS);

    await loadBalance(acc);
    await loadPlants(farmContract, acc);
  }

  /* ----------------------
     Load Balance
  ---------------------- */
  async function loadBalance(acc: string) {
    if (!web3) return;

    log("BALANCE", "Fetching WEED balance", acc);

    const weed = new web3.eth.Contract(
      WeedTokenABI.abi as any,
      WEED_TOKEN_ADDRESS
    );

    const balance = await weed.methods.balanceOf(acc).call();
    setWeedBalance(balance);

    log("BALANCE", "WEED balance loaded", {
      raw: balance,
      formatted: web3.utils.fromWei(balance, "ether"),
    });
  }

  /* ----------------------
     Load Plants
  ---------------------- */
  async function loadPlants(farmContract: Contract, acc: string) {
    if (!web3) return;

    log("PLANTS", "Loading plants for", acc);

    const nft = new web3.eth.Contract(
      PlantNFTABI.abi as any,
      PLANT_NFT_ADDRESS
    );

    const balance = Number(await nft.methods.balanceOf(acc).call());
    log("PLANTS", "NFT balance", balance);

    const owned: number[] = [];
    for (let i = 0; i < balance; i++) {
      const tokenId = await nft.methods
        .tokenOfOwnerByIndex(acc, i)
        .call();
      owned.push(Number(tokenId));
    }

    setPlants(owned);
    log("PLANTS", "Owned token IDs", owned);

    const status: Record<number, boolean> = {};
    for (const id of owned) {
      status[id] = await farmContract.methods
        .isReadyToHarvest(id)
        .call();
      log("PLANTS", `Plant #${id} ready`, status[id]);
    }

    setReady(status);
  }

  /* ----------------------
     Plant
  ---------------------- */
  async function plant(type: number) {
    if (!farm || !account) return;

    setLoading(true);
    log("TX", "Planting seed", { type });

    try {
      const receipt = await farm.methods
        .plant(type)
        .send({ from: account });

      log("TX", "Plant success", receipt.transactionHash);

      await loadPlants(farm, account);
      await loadBalance(account);
    } catch (err) {
      log("ERROR", "Plant failed", err);
    } finally {
      setLoading(false);
    }
  }

  /* ----------------------
     Harvest
  ---------------------- */
  async function harvest(id: number) {
    if (!farm || !account) return;

    setLoading(true);
    log("TX", "Harvesting plant", id);

    try {
      const receipt = await farm.methods
        .harvest(id)
        .send({ from: account });

      log("TX", "Harvest success", receipt.transactionHash);

      await loadPlants(farm, account);
      await loadBalance(account);
    } catch (err) {
      log("ERROR", "Harvest failed", err);
      alert("Harvest failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main style={{ padding: 40 }}>
      <h1>🌱 Weed Farm</h1>

      {loading && <p>Loading...</p>}

      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <>
          <p>Account: {formatAccount(account)}</p>
          <p>
            WEED Balance:{" "}
            {web3 ? web3.utils.fromWei(weedBalance, "ether") : "0"}
          </p>

          <h2>🌱 Plant Seeds</h2>
          <button
            disabled={weedBalance === "0"}
            onClick={() => plant(0)}
          >
            Plant OG Kush
          </button>
          <button
            disabled={weedBalance === "0"}
            onClick={() => plant(1)}
          >
            Plant Blue Dream
          </button>

          <h2>Your Plants</h2>
          {plants.length === 0 && <p>No plants yet</p>}

          {plants.map((id) => (
            <div key={id} style={{ margin: "10px 0" }}>
              Plant #{id} — {ready[id] ? "✅ Ready" : "⏳ Growing"}
              {ready[id] && (
                <button
                  style={{ marginLeft: 10 }}
                  onClick={() => harvest(id)}
                >
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

function formatAccount(addr: string) {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}
