"use client";

import { useWeb3 } from "@/context/Web3Context";
import { AppBar, Button, Toolbar, Typography } from "@mui/material";

export default function Header() {
  const { account, connectWallet } = useWeb3();

  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Supply Chain Tracker
        </Typography>
        {account ? (
          <Typography variant="subtitle1">
            {account.slice(0, 6)}...{account.slice(-4)}
          </Typography>
        ) : (
          <Button color="inherit" onClick={connectWallet}>
            Connect Wallet
          </Button>
        )}
      </Toolbar>
    </AppBar>
  );
}
