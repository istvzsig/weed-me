// scripts/deploy.ts
import { ethers } from "ethers";

import WeedTokenJson from "../artifacts/contracts/WeedToken.sol/WeedToken.json";
import PlantNFTJson from "../artifacts/contracts/PlantNFT.sol/PlantNFT.json";
import FarmGameJson from "../artifacts/contracts/FarmGame.sol/FarmGame.json";

async function main() {
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545"); // Localhost
  const signer = await provider.getSigner(0);
  const address = await signer.getAddress();
  console.log("Using account:", address);

  // Deploy WeedToken
  const WeedTokenFactory = new ethers.ContractFactory(
    WeedTokenJson.abi,
    WeedTokenJson.bytecode,
    signer
  );
  const options = {
    gasLimit: 5000000, // Customize this according to your contract's complexity
    gasPrice: ethers.parseUnits("20", "gwei"), // Adjust based on current network conditions
  };

  const weedToken = await WeedTokenFactory.deploy(
    await signer.getAddress(),
    options
  );

  await weedToken.waitForDeployment();
  console.log("WeedToken deployed at:", weedToken.target);

  // Deploy PlantNFT
  const PlantNFTFactory = new ethers.ContractFactory(
    PlantNFTJson.abi,
    PlantNFTJson.bytecode,
    signer
  );
  const plantNFT = await PlantNFTFactory.deploy(await signer.getAddress());
  await plantNFT.waitForDeployment();
  console.log("PlantNFT deployed at:", plantNFT.target);

  // Deploy FarmGame
  const FarmGameFactory = new ethers.ContractFactory(
    FarmGameJson.abi,
    FarmGameJson.bytecode,
    signer
  );
  const farmGame = await FarmGameFactory.deploy(
    weedToken.target,
    plantNFT.target
  );
  await farmGame.waitForDeployment();
  console.log("FarmGame deployed at:", farmGame.target);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
