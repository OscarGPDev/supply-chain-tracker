"use client";

import { useState, useEffect } from "react";
import {
  Box,
  Button,
  TextField,
  Typography,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  CircularProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
} from "@mui/material";
import {
  getSignerContract,
  ActorRoles,
  Actor,
} from "@/services/supplyChainService";

export default function AdminDashboard() {
  // Actors List State
  const [actors, setActors] = useState<Actor[]>([]);
  const [loading, setLoading] = useState(false);
  const [showInactive, setShowInactive] = useState(false);

  // Register State
  const [openRegister, setOpenRegister] = useState(false);
  const [regForm, setRegForm] = useState({
    address: "",
    name: "",
    role: 1,
    location: "",
  });
  const [regLoading, setRegLoading] = useState(false);

  // Feedback
  const [message, setMessage] = useState<{
    type: "success" | "error";
    text: string;
  } | null>(null);

  const fetchActors = async () => {
    setLoading(true);
    try {
      const contract = await getSignerContract();
      console.log("fetchActors", contract)
      if (!contract) return;
      let data;
      if (showInactive) {
        data = await contract.getInactiveActors(0, 100);
      } else {
        //data = await contract.getActiveActorsCount();
        
        data = await contract.getActiveActors(0, 100);
        console.log("data", data)
      }
      setActors(data);
    } catch (error: any) {
      console.error("Error fetching actors:", error);
      setMessage({
        type: "error",
        text: "Failed to load actors.",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchActors();
  }, [showInactive]);

  const handleRegister = async () => {
    if (!regForm.address) {
      setMessage({ type: "error", text: "Wallet address is required." });
      return;
    }
    if (!/^0x[a-fA-F0-9]{40}$/.test(regForm.address)) {
      setMessage({ type: "error", text: "Invalid wallet address format." });
      return;
    }

    setRegLoading(true);
    setMessage(null);
    try {
      const contract = await getSignerContract();
      console.log("handleRegister", contract,
        regForm.address,
        regForm.name,
        regForm.role,
        regForm.location)
      if (!contract) return;
      const tx = await contract.registerActor(
        regForm.address,
        regForm.name,
        regForm.role,
        regForm.location
      );
      await tx.wait();
      setMessage({ type: "success", text: "Actor registered successfully!" });
      setOpenRegister(false);
      setRegForm({ address: "", name: "", role: 1, location: "" });
      fetchActors();
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

  const handleToggleStatus = async (
    actorAddress: string,
    currentStatus: boolean
  ) => {
    setMessage(null);
    try {
      const contract = await getSignerContract();
      let tx;
      if (currentStatus) {
        tx = await contract.deactivateActor(actorAddress);
      } else {
        tx = await contract.reactivateActor(actorAddress);
      }
      await tx.wait();
      setMessage({
        type: "success",
        text: `Actor ${
          currentStatus ? "deactivated" : "reactivated"
        } successfully!`,
      });
      fetchActors();
    } catch (error: any) {
      console.error(error);
      setMessage({
        type: "error",
        text: error.reason || error.message || "Error updating actor status",
      });
    }
  };

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", mb: 3 }}>
        <Typography variant="h4">Admin Dashboard</Typography>
        <Button variant="contained" onClick={() => setOpenRegister(true)}>
          Register New Actor
        </Button>
      </Box>

      {message && (
        <Alert
          severity={message.type}
          sx={{ mb: 2 }}
          onClose={() => setMessage(null)}
        >
          {message.text}
        </Alert>
      )}

      <Box sx={{ mb: 2, display: "flex", alignItems: "center" }}>
        <FormControlLabel
          control={
            <Switch
              checked={showInactive}
              onChange={(e) => setShowInactive(e.target.checked)}
            />
          }
          label={
            showInactive ? "Showing Inactive Actors" : "Showing Active Actors"
          }
        />
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Address</TableCell>
              <TableCell>Name</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Location</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : actors.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  No {showInactive ? "inactive" : "active"} actors found.
                </TableCell>
              </TableRow>
            ) : (
              actors.map((actor, index) => (
                <TableRow key={index}>
                  <TableCell>{actor.actorAddress}</TableCell>
                  <TableCell>{actor.name}</TableCell>
                  <TableCell>{ActorRoles[Number(actor.role)]}</TableCell>
                  <TableCell>{actor.location}</TableCell>
                  <TableCell>
                    <Chip
                      label={actor.isActive ? "Active" : "Inactive"}
                      color={actor.isActive ? "success" : "error"}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="outlined"
                      color={actor.isActive ? "error" : "success"}
                      size="small"
                      onClick={() =>
                        handleToggleStatus(actor.actorAddress, actor.isActive)
                      }
                    >
                      {actor.isActive ? "Deactivate" : "Reactivate"}
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Register Dialog */}
      <Dialog
        open={openRegister}
        onClose={() => setOpenRegister(false)}
        fullWidth
        maxWidth="sm"
      >
        <DialogTitle>Register New Actor</DialogTitle>
        <DialogContent>
          <Box sx={{ display: "flex", flexDirection: "column", gap: 2, mt: 1 }}>
            <TextField
              label="Wallet Address"
              value={regForm.address}
              onChange={(e) =>
                setRegForm({ ...regForm, address: e.target.value })
              }
              fullWidth
              size="small"
            />
            <TextField
              label="Name"
              value={regForm.name}
              onChange={(e) => setRegForm({ ...regForm, name: e.target.value })}
              fullWidth
              size="small"
            />
            <FormControl fullWidth size="small">
              <InputLabel>Role</InputLabel>
              <Select
                value={regForm.role}
                label="Role"
                onChange={(e) =>
                  setRegForm({ ...regForm, role: Number(e.target.value) })
                }
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
              value={regForm.location}
              onChange={(e) =>
                setRegForm({ ...regForm, location: e.target.value })
              }
              fullWidth
              size="small"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenRegister(false)}>Cancel</Button>
          <Button
            onClick={handleRegister}
            variant="contained"
            disabled={regLoading}
          >
            {regLoading ? <CircularProgress size={24} /> : "Register"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
