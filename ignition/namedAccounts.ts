const namedAccounts: Record<string, Record<string, string>> = {
    consolidationContract: {
      default: "0x00000000219ab540356cBB839Cbe05303d7705Fa",
      localhost: "0x00000000219ab540356cBB839Cbe05303d7705Fa",
      mainnet: "0x00000000219ab540356cBB839Cbe05303d7705Fa",
      holesky: "0x4242424242424242424242424242424242424242",
      devHolesky: "0x4242424242424242424242424242424242424242",
    },
    withdrawalContract: {
      default: "0x00431F263cE400f4455c2dCf564e53007Ca4bbBb",
      localhost: "0x00431F263cE400f4455c2dCf564e53007Ca4bbBb",
      mainnet: "0x00000000219ab540356cBB839Cbe05303d7705Fa",
      holesky: "0x4242424242424242424242424242424242424242",
      devHolesky: "0x4242424242424242424242424242424242424242",
    }, 
    beneficiary: {
      default: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      localhost: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      mainnet: "0x00000000219ab540356cBB839Cbe05303d7705Fa",
      holesky: "0x4242424242424242424242424242424242424242",
      devHolesky: "0x4242424242424242424242424242424242424242",
    },
    owner: {
      default: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      localhost: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      mainnet: "0x00000000219ab540356cBB839Cbe05303d7705Fa",
      holesky: "0x4242424242424242424242424242424242424242",
      devHolesky: "0x4242424242424242424242424242424242424242",
    },
  };

export function getNamedAccounts(name: string, network: string): string {
    return namedAccounts[name][network];
}