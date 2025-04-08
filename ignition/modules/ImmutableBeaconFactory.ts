import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ImmutableBeaconFactoryModule = buildModule("ImmutableBeaconFactoryModule", (m) => {
  const immutableBeaconFactory = m.contract("ImmutableBeaconFactory");
  return { immutableBeaconFactory };
});

export default ImmutableBeaconFactoryModule;