import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("CrossChainNameService", function () {
  const GAS_LIMIT = 1000000; // 1 million gas limit
  const DNS = 'alice.ccns';

  async function deploy() {
    const [deployer, alice] = await ethers.getSigners();
    const localSimulatorFactory = await ethers.getContractFactory("CCIPLocalSimulator");
    // Create an instance of CCIPLocalSimulator.sol smart contract.
    const localSimulator = await localSimulatorFactory.deploy();

    // Call the configuration() function to get Router contract address.
    const config: {
      chainSelector_: bigint;
      sourceRouter_: string;
      destinationRouter_: string;
      wrappedNative_: string;
      linkToken_: string;
      ccipBnM_: string;
      ccipLnM_: string;
    } = await localSimulator.configuration();

    // Create instance of CrossChainNameServiceLookup.sol
    const CrossChainNameServiceLookupFactory = await ethers.getContractFactory('CrossChainNameServiceLookup');
    const CrossChainNameServiceLookupSource = await CrossChainNameServiceLookupFactory.connect(deployer).deploy();
    const CrossChainNameServiceLookupDestination = await CrossChainNameServiceLookupFactory.connect(deployer).deploy();

    // Create instance of CrossChainNameServiceRegister.sol
    const CrossChainNameServiceRegisterFactory = await ethers.getContractFactory('CrossChainNameServiceRegister');
    const CrossChainNameServiceRegisterSource = await CrossChainNameServiceRegisterFactory.connect(deployer).deploy(
      config.sourceRouter_,
      CrossChainNameServiceLookupSource.target
    );
    const CrossChainNameServiceRegisterDestination = await CrossChainNameServiceRegisterFactory.connect(deployer).deploy(
      config.destinationRouter_,
      CrossChainNameServiceLookupDestination.target
    );

    // Create instance of CrossChainNameServiceReceiver.sol
    const CrossChainNameServiceReceiverFactory = await ethers.getContractFactory('CrossChainNameServiceReceiver');
    const CrossChainNameServiceReceiver = await CrossChainNameServiceReceiverFactory.connect(deployer).deploy(
      config.sourceRouter_,
      CrossChainNameServiceLookupDestination.target,
      config.chainSelector_
    );

    return {
      localSimulator,
      CrossChainNameServiceLookupSource,
      CrossChainNameServiceLookupDestination,
      CrossChainNameServiceRegisterSource,
      CrossChainNameServiceRegisterDestination,
      CrossChainNameServiceReceiver,
      config,
      deployer,
      alice
    };
  }

  it('Should register & lookup for cross-chain name service', async () => {
    const {
      CrossChainNameServiceLookupSource,
      CrossChainNameServiceLookupDestination,
      CrossChainNameServiceRegisterSource,
      CrossChainNameServiceRegisterDestination,
      CrossChainNameServiceReceiver,
      config,
      deployer,
      alice
    } = await loadFixture(deploy);

    // Set CrossChainNameService addresses
    await CrossChainNameServiceLookupSource.connect(deployer).setCrossChainNameServiceAddress(CrossChainNameServiceRegisterSource.target);
    await CrossChainNameServiceLookupDestination.connect(deployer).setCrossChainNameServiceAddress(CrossChainNameServiceReceiver.target);

    // Enable CrossChainNameServiceRegister contract on the source chain
    await CrossChainNameServiceRegisterSource.connect(deployer).enableChain(
      config.chainSelector_,
      CrossChainNameServiceReceiver.target,
      GAS_LIMIT
    );

    // Register name with the correct contract
    try {
      await CrossChainNameServiceRegisterSource.connect(alice).register(DNS);
    } catch (error) {
      console.error("Register failed: ", error);
    }

    // Lookup name
    const registeredAddress = await CrossChainNameServiceLookupDestination.lookup(DNS);

    // Alice registered successfully
    expect(registeredAddress).to.equal(alice.address);
  });
});
