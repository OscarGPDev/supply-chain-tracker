"use client";

import { useState } from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  Grid,
  TextField,
  Typography,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  CircularProgress,
  Alert,
} from "@mui/material";
import {
  getSignerContract,
  getContract,
  ActorRoles,
} from "../services/supplyChainService";

export default function AdminDashboard() {
  // Register State
  const [regAddress, setRegAddress] = useState("");
  const [regName, setRegName] = useState("");
  const [regRole, setRegRole] = useState<number>(1);
  const [regLocation, setRegLocation] = useState("");
  const [regLoading, setRegLoading] = useState(false);

  // Deactivate State
  const [deactAddress, setDeactAddress] = useState("");
  const [deactLoading, setDeactLoading] = useState(false);

  // Get Actor State
  const [getAddress, setGetAddress] = useState("");
  const [actorInfo, setActorInfo] = useState<any>(null);
  const [getLoading, setGetLoading] = useState(false);

  // Feedback
  const [message, setMessage] = useState<{
    type: "success" | "error";
    text: string;
  } | null>(null);

  const handleRegister = async () => {
    setRegLoading(true);
    setMessage(null);
    try {
      const contract = await getSignerContract();
      const tx = await contract.registerActor(
        regAddress,
        regName,
        regRole,
        regLocation
      );
      await tx.wait();
      setMessage({ type: "success", text: "Actor registered successfully!" });
      setRegAddress("");
      setRegName("");
      setRegLocation("");
    } catch (error: any) {
      console.error(error);
      setMessage({
        type: "error",
        text: error.reason || error.message || "Error registering actor",
      });
    } finally {
      setRegLoading(false);
    }
  };

  const handleDeactivate = async () => {
    setDeactLoading(true);
    setMessage(null);
    try {
      const contract = await getSignerContract();
      const tx = await contract.deactivateActor(deactAddress);
      await tx.wait();
      setMessage({ type: "success", text: "Actor deactivated successfully!" });
      setDeactAddress("");
    } catch (error: any) {
      console.error(error);
      setMessage({
        type: "error",
        text: error.reason || error.message || "Error deactivating actor",
      });
    } finally {
      setDeactLoading(false);
    }
  };

  const handleGetActor = async () => {
    setGetLoading(true);
    setActorInfo(null);
    setMessage(null);
    try {
      const contract = getContract();
      if (!contract) throw new Error("No provider");
      const data = await contract.getActor(getAddress);

      if (
        data.actorAddress === "0x0000000000000000000000000000000000000000"
      ) {
        setMessage({ type: "error", text: "Actor not found." });
      } else {
        setActorInfo(data);
      }
    } catch (error: any) {
      console.error(error);
      setMessage({
        type: "error",
        text: error.reason || error.message || "Error fetching actor",
      });
    } finally {
      setGetLoading(false);
    }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <Typography variant="h4" gutterBottom>
        Admin Dashboard
      </Typography>

      {message && (
        <Alert
          severity={message.type}
          sx={{ mb: 2 }}
          onClose={() => setMessage(null)}
        >
          {message.text}
        </Alert>
      )}

      <Grid container spacing={3}>
        {/* Register Actor */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Register New Actor
              </Typography>
              <Box
                component="form"
                sx={{ display: "flex", flexDirection: "column", gap: 2 }}
              >
                <TextField
                  label="Wallet Address"
                  value={regAddress}
                  onChange={(e) => setRegAddress(e.target.value)}
                  fullWidth
                  size="small"
                />
                <TextField
                  label="Name"
                  value={regName}
                  onChange={(e) => setRegName(e.target.value)}
                  fullWidth
                  size="small"
                />
                <FormControl fullWidth size="small">
                  <InputLabel>Role</InputLabel>
                  <Select
                    value={regRole}
                    label="Role"
                    onChange={(e) => setRegRole(Number(e.target.value))}
                  >
                    {Object.entries(ActorRoles).map(
                      ([key, val]) =>
                        key !== "0" && (
                          <MenuItem key={key} value={key}>
                            {val}
                          </MenuItem>
                        )
                    )}
                  </Select>
                </FormControl>
                <TextField
                  label="Location"
                  value={regLocation}
                  onChange={(e) => setRegLocation(e.target.value)}
                  fullWidth
                  size="small"
                />
                <Button
                  variant="contained"
                  onClick={handleRegister}
                  disabled={regLoading}
                >
                  {regLoading ? (
                    <CircularProgress size={24} />
                  ) : (
                    "Register Actor"
                  )}
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Deactivate & Get Actor */}
        <Grid item xs={12} md={6}>
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Deactivate Actor
              </Typography>
              <Box sx={{ display: "flex", gap: 2 }}>
                <TextField
                  label="Wallet Address"
                  value={deactAddress}
                  onChange={(e) => setDeactAddress(e.target.value)}
                  fullWidth
                  size="small"
                />
                <Button
                  variant="contained"
                  color="error"
                  onClick={handleDeactivate}
                  disabled={deactLoading}
                >
                  {deactLoading ? (
                    <CircularProgress size={24} />
                  ) : (
                    "Deactivate"
                  )}
                </Button>
              </Box>
            </CardContent>
          </Card>

          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Get Actor Details
              </Typography>
              <Box sx={{ display: "flex", gap: 2, mb: 2 }}>
                <TextField
                  label="Wallet Address"
                  value={getAddress}
                  onChange={(e) => setGetAddress(e.target.value)}
                  fullWidth
                  size="small"
                />
                <Button
                  variant="contained"
                  onClick={handleGetActor}
                  disabled={getLoading}
                >
                  {getLoading ? <CircularProgress size={24} /> : "Search"}
                </Button>
              </Box>

              {actorInfo && (
                <Box
                  sx={{
                    mt: 2,
                    p: 2,
                    bgcolor: "background.default",
                    borderRadius: 1,
                  }}
                >
                  <Typography variant="subtitle2">
                    Name: {actorInfo.name}
                  </Typography>
                  <Typography variant="subtitle2">
                    Role: {ActorRoles[Number(actorInfo.role)]}
                  </Typography>
                  <Typography variant="subtitle2">
                    Location: {actorInfo.location}
                  </Typography>
                  <Typography
                    variant="subtitle2"
                    color={
                      actorInfo.isActive ? "success.main" : "error.main"
                    }
                  >
                    Status: {actorInfo.isActive ? "Active" : "Inactive"}
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
