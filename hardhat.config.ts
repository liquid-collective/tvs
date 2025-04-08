import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  paths: {
    cache: "./cache_hardhat",
  }
};

export default config;