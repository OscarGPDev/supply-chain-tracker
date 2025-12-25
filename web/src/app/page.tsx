"use client";

import { useWeb3 } from "@/context/Web3Context";
import { ActorRoles } from "@/services/supplyChainService";

export default function Home() {
  const { account, actor, isAdmin, connectWallet } = useWeb3();

  const renderDashboard = () => {
    if (!account) {
      return <p>Please connect your wallet to continue.</p>;
    }

    if (isAdmin) {
      return <div>Welcome Admin! You can register new actors.</div>;
    }

    if (!actor) {
      return (
        <div>
          Your address is not registered as an active actor in the system.
        </div>
      );
    }

    switch (actor.role) {
      case 1: // Sender
        return <div>Welcome Sender! You can create new shipments.</div>;
      case 2: // Carrier
        return <div>Welcome Carrier! You can record checkpoints.</div>;
      case 4: // Recipient
        return <div>Welcome Recipient! You can confirm deliveries.</div>;
      default:
        return <div>Welcome! Your role is: {ActorRoles[actor.role]}</div>;
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center p-24">
      <header className="w-full max-w-5xl items-center justify-between font-mono text-sm lg:flex">
        <h1 className="text-2xl font-bold">Supply Chain dApp</h1>
        {account ? (
          <div className="text-right">
            <p>Connected: {`${account.substring(0, 6)}...${account.substring(account.length - 4)}`}</p>
            {actor && <p>Role: {ActorRoles[actor.role]}</p>}
            {isAdmin && <p>Role: Admin</p>}
          </div>
        ) : (
          <button onClick={connectWallet} className="px-4 py-2 font-semibold text-white bg-blue-500 rounded hover:bg-blue-700">Connect Wallet</button>
        )}
      </header>

      <section className="mt-16">{renderDashboard()}</section>
    </main>
  );
}
