"use client";

import { useWeb3 } from "@/context/Web3Context";
import { ActorRoles } from "@/services/supplyChainService";
import {
  Box,
  Container,
  Paper,
  Typography,
} from "@mui/material";

export default function Home() {
  const { account, actor, isAdmin } = useWeb3();

  const renderDashboard = () => {
    if (!account) {
      return (
        <Typography variant="h5" component="p" textAlign="center">
          Please connect your wallet to continue.
        </Typography>
      );
    }

    if (isAdmin) {
      return (
        <Typography variant="h5">
          Welcome Admin! You can register new actors.
        </Typography>
      );
      
    }

    if (!actor) {
      return (
        <Typography variant="h5" color="error">
          Your address is not registered as an active actor in the system.
        </Typography>
      );
    }

    switch (actor.role) {
      case 1: // Sender
        return (
          <Typography variant="h5">
            Welcome Sender! You can create new shipments.
          </Typography>
        );
      case 2: // Carrier
        return (
          <Typography variant="h5">
            Welcome Carrier! You can record checkpoints.
          </Typography>
        );
      case 4: // Recipient
        return (
          <Typography variant="h5">
            Welcome Recipient! You can confirm deliveries.
          </Typography>
        );
      default:
        return (
          <Typography variant="h5">
            Welcome! Your role is: {ActorRoles[actor.role]}
          </Typography>
        );
    }
  };

  return (
    <Box>
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Paper elevation={3} sx={{ p: 3, mt: 4, textAlign: "center" }}>
          {renderDashboard()}
        </Paper>
      </Container>
    </Box>
  );
}
