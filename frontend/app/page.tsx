"use client";

import { useEffect, useState } from "react";
import Web3 from "web3";
import type { Contract } from "web3-eth-contract";
import type { ContractAbi } from "web3-types";

import FarmGameABI from "../abi/FarmGame.json";
import WeedTokenABI from "../abi/WeedToken.json";
import PlantNFTABI from "../abi/PlantNFT.json";

import { log, formatAccount, initWeb3Contract } from "./utils";

/* --------------------------------------------------
   ENV (must be NEXT_PUBLIC_*)
-------------------------------------------------- */
const WEED_TOKEN_ADDRESS = process.env.WEED_TOKEN_ADDRESS!;
const PLANT_NFT_ADDRESS = process.env.PLANT_NFT_ADDRESS!;
const FARM_GAME_ADDRESS = process.env.FARM_GAME_ADDRESS!;

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

  /* --------------------------------------------------
     Init Web3 once
  -------------------------------------------------- */
  useEffect(() => {
    if (!window.ethereum) {
      alert("Please install MetaMask");
      return;
    }

    const w3 = new Web3(window.ethereum);
    setWeb3(w3);
    log("WEB3", "Initialized");
  }, []);

  /* --------------------------------------------------
     Connect Wallet
  -------------------------------------------------- */
  async function connectWallet() {
    if (!web3) return;

    const accounts = await web3.eth.requestAccounts();
    const acc = accounts[0];
    if (!acc) return;

    setAccount(acc);
    log("WALLET", "Connected", acc);

    if (!WEED_TOKEN_ADDRESS || !PLANT_NFT_ADDRESS || !FARM_GAME_ADDRESS) {
      throw new Error("Missing contract addresses");
    }

    const farm = initWeb3Contract(web3, FarmGameABI, FARM_GAME_ADDRESS);
    const weed = initWeb3Contract(web3, WeedTokenABI, WEED_TOKEN_ADDRESS);
    const plantNFT = initWeb3Contract(web3, PlantNFTABI, PLANT_NFT_ADDRESS);

    const loaded = { farm, weed, plantNFT };
    setContracts(loaded);

    log("LOAD", "Fetching balances & plants");
    await loadWeedBalance(acc, weed);
    await loadPlants(acc, farm);
  }

  /* --------------------------------------------------
     Load WEED balance (ERC20)
  -------------------------------------------------- */
  async function loadWeedBalance(acc: string, weed: Contract<ContractAbi>) {
    const symbol = await weed.methods.symbol().call();
    if (symbol !== "WEED") {
      throw new Error("Wrong contract used for WeedToken");
    }
    const balance = await weed.methods.balanceOf(acc).call();
    setWeedBalance(balance);
    log("BALANCE", "WEED", balance);
  }

  /* --------------------------------------------------
     Load Plants
  -------------------------------------------------- */
  async function loadPlants(acc: string, farm: Contract<ContractAbi>) {
    const ids: string[] = await farm.methods.getPlayerPlants(acc).call();
    const parsed = ids.map(Number);
    setPlants(parsed);

    const status: Record<number, boolean> = {};
    for (const id of parsed) {
      status[id] = await farm.methods.isReadyToHarvest(id).call();
    }
    setReady(status);
  }

  /* --------------------------------------------------
     Approve WEED
  -------------------------------------------------- */
  async function ensureApproval(requiredWei: string) {
    if (!contracts || !account) return;

    const allowance = await contracts.weed.methods
      .allowance(account, FARM_GAME_ADDRESS)
      .call();

    if (BigInt(allowance) < BigInt(requiredWei)) {
      await contracts.weed.methods
        .approve(FARM_GAME_ADDRESS, web3!.utils.toWei("1000000", "ether"))
        .send({ from: account });
    }
  }

  /* --------------------------------------------------
     Plant
  -------------------------------------------------- */
  async function plant(type: number) {
    if (!contracts || !account || !web3) return;

    setLoading(true);
    try {
      await ensureApproval(web3.utils.toWei("10", "ether"));
      await contracts.farm.methods.plant(type).send({ from: account });

      await loadPlants(account, contracts.farm);
      await loadWeedBalance(account, contracts.weed);
    } finally {
      setLoading(false);
    }
  }

  /* --------------------------------------------------
     Harvest
  -------------------------------------------------- */
  async function harvest(id: number) {
    if (!contracts || !account) return;

    setLoading(true);
    try {
      await contracts.farm.methods.harvest(id).send({ from: account });
      await loadPlants(account, contracts.farm);
      await loadWeedBalance(account, contracts.weed);
    } finally {
      setLoading(false);
    }
  }

  /* --------------------------------------------------
     Faucet (DEV ONLY)
  -------------------------------------------------- */
  async function buyWeed() {
    if (!contracts || !account || !web3) return;

    setLoading(true);
    try {
      await contracts.farm.methods.buyWeed().send({
        from: account,
        value: web3.utils.toWei("0.001", "ether"),
      });
      await loadWeedBalance(account, contracts.weed);
    } finally {
      setLoading(false);
    }
  }

  /* --------------------------------------------------
     UI
  -------------------------------------------------- */
  return (
    <main style={{ padding: 40 }}>
      <h1>🌱 Weed Farm</h1>

      {loading && <p>Loading...</p>}

      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <>
          <p>Wallet: {formatAccount(account)}</p>
          <p>WEED: {web3?.utils.fromWei(weedBalance, "ether")}</p>

          <h2>🌱 Plant</h2>
          <button onClick={() => plant(0)}>Plant OG Kush</button>
          <button onClick={() => plant(1)}>Plant Blue Dream</button>

          <h2>🪙 Faucet</h2>
          <button onClick={buyWeed}>Buy WEED (dev)</button>

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
