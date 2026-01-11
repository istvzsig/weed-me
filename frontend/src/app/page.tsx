"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";

export default function Home() {
  const [account, setAccount] = useState<string | null>(null);

  async function connectWallet() {
    if (!window.ethereum) {
      alert("Install MetaMask");
      return;
    }

    const provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts", []);
    setAccount(accounts[0]);
  }

  return (
    <main style={{ padding: 40 }}>
      <h1>🌱 Weed Me</h1>

      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <p>Connected: {account}</p>
      )}
    </main>
  );
}
