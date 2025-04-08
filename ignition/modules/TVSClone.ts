import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { deployTVS } from "../deployTVS";

const TVSCloneModule = buildModule("TVSCloneModule", (m) => {
  const tvsClone = deployTVS(m, "TVSClone");
  return { tvsClone };
});

export default TVSCloneModule;