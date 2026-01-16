"use client";

import { useEffect, useState } from "react";
import Web3 from "web3";
import type { Contract } from "web3-eth-contract";
import type { ContractAbi } from "web3-types";

import FarmGameABI from "../abi/FarmGame.sol/FarmGame.json";
import WeedTokenABI from "../abi/WeedToken.sol/WeedToken.json";
import PlantNFTABI from "../abi/PlantNFT.sol/PlantNFT.json";

const WEED_TOKEN_ADDRESS = process.env.WEED_TOKEN_ADDRESS;
const PLANT_NFT_ADDRESS = process.env.PLANT_NFT_ADDRESS;
const FARM_GAME_ADDRESS = process.env.FARM_GAME_ADDRESS;

console.log({WEED_TOKEN_ADDRESS, PLANT_NFT_ADDRESS, FARM_GAME_ADDRESS});

type Contracts = {
  farm: Contract<ContractAbi>;
  weed: Contract<ContractAbi>;
  plantNFT: Contract<ContractAbi>;
};

export default function Home() {
  const [web3, setWeb3] = useState<Web3 | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [contracts, setContracts] = useState<Contracts | null>(null);

  const [loading, setLoading] = useState(false);
  const [plants, setPlants] = useState<number[]>([]);
  const [weedBalance, setWeedBalance] = useState<string>("0");
  const [ready, setReady] = useState<Record<number, boolean>>({});

  /* ----------------------
     Init Web3
  ---------------------- */
  useEffect(() => {
    if (!(window as any).ethereum) {
      alert("Please install MetaMask");
      return;
    }

    const w3 = new Web3((window as any).ethereum);
    setWeb3(w3);
    log("WEB3", "Provider initialized");
  }, []);

  /* ----------------------
     Connect Wallet + Init Contracts
  ---------------------- */
  async function connectWallet() {
    if (!web3) return;

    const accounts = await web3.eth.requestAccounts();
    if (!accounts.length) return;

    const acc = accounts[0];
    setAccount(acc);

    const farm = new web3.eth.Contract(
      FarmGameABI.abi as ContractAbi,
      FARM_GAME_ADDRESS
    );

    const weed = new web3.eth.Contract(
      WeedTokenABI.abi as ContractAbi,
      WEED_TOKEN_ADDRESS
    );

    const plantNFT = new web3.eth.Contract(
      PlantNFTABI.abi as ContractAbi,
      PLANT_NFT_ADDRESS
    );

    setContracts({ farm, weed, plantNFT });

    log("WALLET", "Connected", acc);
    log("CONTRACTS", "All contracts initialized");

    await loadBalance(acc, weed);
    await loadPlants(acc, farm, plantNFT);
  }

  /* ----------------------
     Load Balance
  ---------------------- */
  async function loadBalance(acc: string, weed: Contract) {
    const balance = await weed.methods.balanceOf(acc).call();
    setWeedBalance(balance);
    log("BALANCE", "WEED loaded", balance);
  }

  /* ----------------------
     Approval
  ---------------------- */
  async function ensureApproval(required: string) {
    if (!contracts || !account || !web3) return;

    const allowance = await contracts.weed.methods
      .allowance(account, FARM_GAME_ADDRESS)
      .call();

    if (BigInt(allowance) < BigInt(required)) {
      log("APPROVAL", "Approving WEED");

      await contracts.weed.methods
        .approve(FARM_GAME_ADDRESS, web3.utils.toWei("1000000", "ether"))
        .send({ from: account });
    }
  }

  /* ----------------------
     Load Plants
  ---------------------- */
  async function loadPlants(acc: string, farm: Contract, plantNFT: Contract) {
    const balance = Number(await plantNFT.methods.balanceOf(acc).call());

    const owned: number[] = [];
    for (let i = 0; i < balance; i++) {
      const tokenId = await plantNFT.methods.tokenOfOwnerByIndex(acc, i).call();
      owned.push(Number(tokenId));
    }

    setPlants(owned);

    const status: Record<number, boolean> = {};
    for (const id of owned) {
      status[id] = await farm.methods.isReadyToHarvest(id).call();
    }

    setReady(status);
  }

  /* ----------------------
     Plant
  ---------------------- */
  async function plant(type: number) {
    if (!contracts || !account || !web3) return;

    setLoading(true);
    try {
      await ensureApproval(web3.utils.toWei("10", "ether"));
      await contracts.farm.methods.plant(type).send({ from: account });

      await loadPlants(account, contracts.farm, contracts.plantNFT);
      await loadBalance(account, contracts.weed);
    } finally {
      setLoading(false);
    }
  }

  /* ----------------------
     Harvest
  ---------------------- */
  async function harvest(id: number) {
    if (!contracts || !account) return;

    setLoading(true);
    try {
      await contracts.farm.methods.harvest(id).send({ from: account });

      await loadPlants(account, contracts.farm, contracts.plantNFT);
      await loadBalance(account, contracts.weed);
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
          <button disabled={weedBalance === "0"} onClick={() => plant(0)}>
            Plant OG Kush
          </button>
          <button disabled={weedBalance === "0"} onClick={() => plant(1)}>
            Plant Blue Dream
          </button>

          <h2>Your Plants</h2>
          {plants.length === 0 && <p>No plants yet</p>}

          {plants.map((id) => (
            <div key={id}>
              Plant #{id} — {ready[id] ? "✅ Ready" : "⏳ Growing"}
              {ready[id] && (
                <button onClick={() => harvest(id)}>Harvest</button>
              )}
            </div>
          ))}
        </>
      )}
    </main>
  );
}

/* ----------------------
   Utils
---------------------- */
function formatAccount(addr: string) {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}

function log(scope: string, message: string, data?: unknown) {
  console.log(
    `%c[${scope}]`,
    "color:#22c55e;font-weight:bold",
    message,
    data ?? ""
  );
}
