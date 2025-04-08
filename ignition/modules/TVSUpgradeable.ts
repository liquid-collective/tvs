import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { deployTVS } from "../deployTVS";

const TVSUpgradeableModule = buildModule("TVSUpgradeableModule", (m) => {
  const tvsUpgradeable = deployTVS(m, "TVSUpgradeable");
  return { tvsUpgradeable };
});

export default TVSUpgradeableModule;