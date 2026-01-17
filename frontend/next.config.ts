import path from "path";
import dotenv from "dotenv"

dotenv.config({ path: path.resolve(__dirname, "../.env") });

/** @type {import('next').NextConfig} */
const nextConfig: import('next').NextConfig = {
  turbopack: { root: __dirname },
  env: {
    WEED_TOKEN_ADDRESS: process.env.WEED_TOKEN_ADDRESS,
    PLANT_NFT_ADDRESS: process.env.PLANT_NFT_ADDRESS,
    FARM_GAME_ADDRESS: process.env.FARM_GAME_ADDRESS,
  },
};

module.exports = nextConfig;
