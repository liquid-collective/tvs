import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { deployTVS } from "../deployTVS";

const TVSImmutableModule = buildModule("TVSImmutableModule", (m) => {
  const tvsImmutable = deployTVS(m, "TVSImmutable");

  console.log({tvsImmutable});
  return { tvsImmutable };
});

export default TVSImmutableModule;