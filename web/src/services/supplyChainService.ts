import { ethers } from "ethers";
import SupplyChainABI from "../abi/SupplyChain.json";

// The address of your deployed SupplyChain contract
// It's better to store this in an environment variable
const contractAddress =
  process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ||
  "YOUR_DEPLOYED_CONTRACT_ADDRESS";

// Helper to get a provider
const getEthersProvider = () => {
  if (typeof window.ethereum === "undefined") {
    // We can't assume window.ethereum is present, as this can run on the server.
    // On the server, we can use a read-only provider.
    // For client-side, we'll handle the MetaMask check in the component.
    return null;
  }
  return new ethers.BrowserProvider(window.ethereum);
};

// Get a read-only contract instance
export const getContract = () => {
  const provider = getEthersProvider();
  // A provider is needed for read-only calls. If it's null, we can't create a contract instance.
  if (!provider) return null;
  return new ethers.Contract(contractAddress, SupplyChainABI.abi, provider);
};

// Get a contract instance that can sign transactions
export const getSignerContract = async () => {
  const provider = getEthersProvider();
  if (!provider) throw new Error("MetaMask is not installed!");
  const signer = await provider.getSigner();
  return new ethers.Contract(contractAddress, SupplyChainABI.abi, signer);
};

// For your enums, it's useful to have a mapping
export const ActorRoles: { [key: number]: string } = {
  0: "None",
  1: "Sender",
  2: "Carrier",
  3: "Hub",
  4: "Recipient",
  5: "Inspector",
};

