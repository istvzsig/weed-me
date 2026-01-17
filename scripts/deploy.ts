// scripts/deploy.ts
import { ethers } from "ethers";

import WeedTokenJson from "../artifacts/contracts/WeedToken.sol/WeedToken.json";
import PlantNFTJson from "../artifacts/contracts/PlantNFT.sol/PlantNFT.json";
import FarmGameJson from "../artifacts/contracts/FarmGame.sol/FarmGame.json";

async function main() {
  const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  const signer = await provider.getSigner(0);

  const WeedTokenFactory = new ethers.ContractFactory(
    WeedTokenJson.abi,
    WeedTokenJson.bytecode,
    signer,
  );
  const weedToken = await WeedTokenFactory.deploy();
  await weedToken.waitForDeployment();

  const PlantNFTFactory = new ethers.ContractFactory(
    PlantNFTJson.abi,
    PlantNFTJson.bytecode,
    signer,
  );
  const plantNFT = await PlantNFTFactory.deploy(await signer.getAddress());
  await plantNFT.waitForDeployment();

  const FarmGameFactory = new ethers.ContractFactory(
    FarmGameJson.abi,
    FarmGameJson.bytecode,
    signer,
  );
  const farmGame = await FarmGameFactory.deploy(
    weedToken.target,
    plantNFT.target,
    true, // local/test otherwise turn off faucet
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

  await (await weedTokenContract.transferOwnership(farmGame.target)).wait();
  await (await plantNFTContract.transferOwnership(farmGame.target)).wait();

  console.log("WeedToken:", weedToken.target);
  console.log("PlantNFT:", plantNFT.target);
  console.log("FarmGame:", farmGame.target);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
