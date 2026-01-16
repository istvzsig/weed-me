import { defineConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";

export default defineConfig({
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    localhost: {
      type: "http",
      url: "http://127.0.0.1:8545",
    },
  },
});
