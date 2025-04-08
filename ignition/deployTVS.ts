import { hardhatArguments } from "hardhat";
import { getNamedAccounts } from "./namedAccounts";
import ImmutableBeaconFactory  from "./modules/ImmutableBeaconFactory";

export function deployTVS(m: any, contractName: string) {
    const network = hardhatArguments.network || "default";
  
    // Define parameters for the module
    let args: string[] = [];
    if(contractName == "TVSImmutable" || contractName == "TVSFlexibleImmutable") {
      const beneficiary = getNamedAccounts("beneficiary", network);
      const owner = getNamedAccounts("owner", network);
      args = [beneficiary, owner];
    }

    const withdrawalContract = getNamedAccounts("withdrawalContract", network);
    const consolidationContract = getNamedAccounts("consolidationContract", network);

    args = [...args, withdrawalContract, consolidationContract]; 

    if(contractName == "TVSUpgradeable") {
      const immutableBeaconFactory = m.useModule(ImmutableBeaconFactory);
      args = [...args, immutableBeaconFactory.immutableBeaconFactory];  
    }

    // Deploy the contract
    return m.contract(contractName, args);

  }
