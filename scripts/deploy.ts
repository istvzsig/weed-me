// scripts/deploy.ts
import { ethers } from "ethers";

import WeedTokenJson from "../artifacts/contracts/WeedToken.sol/WeedToken.json" with { type: "json" };
import SeedNFTJson from "../artifacts/contracts/SeedNFT.sol/SeedNFT.json" with { type: "json" };
import PlantNFTJson from "../artifacts/contracts/PlantNFT.sol/PlantNFT.json" with { type: "json" };
import FarmGameJson from "../artifacts/contracts/FarmGame.sol/FarmGame.json" with { type: "json" };

async function main() {
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545"); // Extract magic string to process
  const signer = await provider.getSigner(0);

  // Init
  const WeedTokenFactory = new ethers.ContractFactory(
    WeedTokenJson.abi,
    WeedTokenJson.bytecode,
    signer,
  );
  const SeedNFTFactory = new ethers.ContractFactory(
    SeedNFTJson.abi,
    SeedNFTJson.bytecode,
    signer,
  );
  const PlantNFTFactory = new ethers.ContractFactory(
    PlantNFTJson.abi,
    PlantNFTJson.bytecode,
    signer,
  );
  const FarmGameFactory = new ethers.ContractFactory(
    FarmGameJson.abi,
    FarmGameJson.bytecode,
    signer,
  );

  // Deploy
  const weedToken = await WeedTokenFactory.deploy();
  await weedToken.waitForDeployment();
  const seedNFT = await SeedNFTFactory.deploy(await signer.getAddress());
  await seedNFT.waitForDeployment();
  const plantNFT = await PlantNFTFactory.deploy(await signer.getAddress());
  await plantNFT.waitForDeployment();
  const farmGame = await FarmGameFactory.deploy(
    weedToken.target,
    plantNFT.target,
    seedNFT.target,
    true, // faucetEnabled for local
    await signer.getAddress(), // treasury
  );
  await farmGame.waitForDeployment();

  const weedTokenContract = new ethers.Contract(
    weedToken.target,
    WeedTokenJson.abi,
    signer,
  );
  const plantNFTContract = new ethers.Contract(
    plantNFT.target,
    PlantNFTJson.abi,
    signer,
  );
  const seedNFTContract = new ethers.Contract(
    seedNFT.target,
    SeedNFTJson.abi,
    signer,
  );

  // Transfer ownership
  await (await seedNFTContract.transferOwnership(farmGame.target)).wait();
  await (await weedTokenContract.transferOwnership(farmGame.target)).wait();
  await (await plantNFTContract.transferOwnership(farmGame.target)).wait();

  console.log("WeedToken:", weedToken.target);
  console.log("SeedNFT:", seedNFT.target);
  console.log("PlantNFT:", plantNFT.target);
  console.log("FarmGame:", farmGame.target);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
