import Web3, { ContractAbi } from "web3";

export function log(scope: string, message: string, data?: unknown) {
  console.log(
    `%c[${scope}]`,
    "color:#22c55e;font-weight:bold",
    message,
    data ?? ""
  );
}

export function formatAccount(addr: string) {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}

/* --------------------------------------------------
   Contract helper
-------------------------------------------------- */
export function initWeb3Contract(
  web3: Web3,
  artifact: { abi: ContractAbi },
  address: string
) {
  if (!address) {
    throw new Error("Contract address not specified");
  }

  const contract = new web3.eth.Contract(artifact.abi, address);
  log("CONTRACT", `Loaded at ${address}`);
  return contract;
}
