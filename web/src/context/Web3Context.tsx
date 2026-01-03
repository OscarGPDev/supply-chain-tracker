"use client";

import {
  createContext,
  useState,
  useEffect,
  useContext,
  ReactNode,
} from "react";
import { getSignerContract, Actor } from "../services/supplyChainService";

interface Web3ContextType {
  account: string | null;
  actor: Actor | null;
  isAdmin: boolean;
  connectWallet: () => Promise<void>;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined);

export const Web3Provider = ({ children }: { children: ReactNode }) => {
  const [account, setAccount] = useState<string | null>(null);
  const [actor, setActor] = useState<Actor | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);

  const connectWallet = async () => {
    try {
      if (typeof window.ethereum === "undefined") {
        alert("Please install MetaMask.");
        return;
      }
      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });
      setAccount(accounts[0]);
    } catch (error) {
      console.error("Error connecting wallet:", error);
    }
  };

  useEffect(() => {
    const fetchActorData = async () => {
      if (!account) return;
      try {
        const contract = await getSignerContract();
        if (!contract) return;
        console.log("getActor",contract)
        const actorData = await contract.getActor();
        console.log("getActorData",actorData)
        const isAdmin = await contract.isAdmin();
        console.log("isAdmin",isAdmin)
        if (
          actorData.actorAddress !== "0x0000000000000000000000000000000000000000" &&
          actorData.isActive
        ) {
          setActor({
            actorAddress: actorData.actorAddress,
            name: actorData.name,
            role: Number(actorData.role),
            location: actorData.location,
            isActive: actorData.isActive,
          });
        } else {
          setActor(null);
        }

        setIsAdmin(isAdmin);
      } catch (error) {
        console.error("Failed to fetch actor data:", error);
        setActor(null);
      }
    };

    fetchActorData();

    if (window.ethereum) {
      window.ethereum.on("accountsChanged", (accounts: string[]) => {
        setAccount(accounts[0] || null);
      });
    }
  }, [account]);

  return (
    <Web3Context.Provider value={{ account, actor, isAdmin, connectWallet }}>
      {children}
    </Web3Context.Provider>
  );
};

export const useWeb3 = () => {
  const context = useContext(Web3Context);
  if (context === undefined) {
    throw new Error("useWeb3 must be used within a Web3Provider");
  }
  return context;
};