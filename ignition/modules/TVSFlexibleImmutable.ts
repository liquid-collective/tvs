import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { deployTVS } from "../deployTVS";

const TVSFlexibleImmutableModule = buildModule("TVSFlexibleImmutableModule", (m) => {
  const tvsFlexibleImmutable = deployTVS(m, "TVSFlexibleImmutable");
  return { tvsFlexibleImmutable };
});

export default TVSFlexibleImmutableModule;