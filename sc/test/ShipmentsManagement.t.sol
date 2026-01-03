// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/ShipmentsManagement.sol";
import "../src/Structs/ShipmentStructures.sol";
import "../src/Structs/ActorStructures.sol";
import "../src/Structs/CheckpointsStructures.sol";
import "../src/Structs/IncidentStructures.sol";

contract ShipmentsManagementTest is Test {
    ShipmentsManagement public shipmentsManagement;
    address public admin;
    address public sender;
    address public recipient;
    address public carrier;
    
    function setUp() public {
        // Deploy the contract
        shipmentsManagement = new ShipmentsManagement();
        
        // Get addresses
        admin = address(this);
        sender = address(0x1);
        recipient = address(0x2);
        carrier = address(0x3);
    }
    
    function testCreateShipment() public {
        string memory product = "Medicine";
        string memory origin = "Warehouse A";
        string memory destination = "Hospital B";
        bool requiresColdChain = true;
        
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, product, origin, destination, requiresColdChain);
        
        // Verify shipment was created
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(shipment.id, shipmentId);
        assertEq(shipment.sender, sender);
        assertEq(shipment.recipient, recipient);
        assertEq(shipment.product, product);
        assertEq(shipment.origin, origin);
        assertEq(shipment.destination, destination);
        assertTrue(shipment.requiresColdChain);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.Created));
        assertEq(shipment.dateCreated, block.timestamp);
        assertEq(shipment.checkpointIds.length, 0);
        assertEq(shipment.incidentIds.length, 0);
    }
    
    function testGetShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Get the shipment
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(shipment.id, shipmentId);
        assertEq(shipment.sender, sender);
        assertEq(shipment.recipient, recipient);
    }
    
    function testUpdateShipmentStatus() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Update status
        vm.prank(sender);
        shipmentsManagement.updateShipmentStatus(shipmentId, ShipmentStructures.ShipmentStatus.InTransit);
        
        // Verify status was updated
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.InTransit));
    }
    
    function testConfirmDelivery() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Confirm delivery as recipient
        vm.prank(recipient);
        shipmentsManagement.confirmDelivery(shipmentId);
        
        // Verify status was updated
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.Delivered));
        assertEq(shipment.dateDelivered, block.timestamp);
    }
    
    function testConfirmDeliveryNotRecipient() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Try to confirm delivery as someone other than recipient - should fail
        vm.prank(carrier);
        vm.expectRevert("Only recipient can confirm delivery");
        shipmentsManagement.confirmDelivery(shipmentId);
    }
    
    function testCancelShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Cancel shipment as sender
        vm.prank(sender);
        shipmentsManagement.cancelShipment(shipmentId);
        
        // Verify status was updated
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.Cancelled));
    }
    
    function testCancelShipmentNotSenderOrRecipient() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Try to cancel shipment as someone other than sender or recipient - should fail
        vm.prank(carrier);
        vm.expectRevert("Only sender or recipient can cancel shipment");
        shipmentsManagement.cancelShipment(shipmentId);
    }
    
    function testRecordCheckpoint() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoint
        string memory location = "Hub 1";
        string memory checkpointType = "Transit";
        string memory notes = "Temperature check";
        int256 temperature = 50; // 5.0 degrees Celsius
        
        vm.prank(carrier);
        uint256 checkpointId = shipmentsManagement.recordCheckpoint(shipmentId, location, checkpointType, notes, temperature);
        
        // Verify checkpoint was recorded
        CheckpointsStructures.Checkpoint memory checkpoint = shipmentsManagement.getCheckpoint(checkpointId);
        assertEq(checkpoint.id, checkpointId);
        assertEq(checkpoint.shipmentId, shipmentId);
        assertEq(checkpoint.actor, carrier);
        assertEq(checkpoint.location, location);
        assertEq(checkpoint.checkpointType, checkpointType);
        assertEq(checkpoint.temperature, temperature);
        
        // Verify checkpoint was added to shipment
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(shipment.checkpointIds.length, 1);
        assertEq(shipment.checkpointIds[0], checkpointId);
    }
    
    function testRecordCheckpointOnCancelledShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Cancel the shipment
        vm.prank(sender);
        shipmentsManagement.cancelShipment(shipmentId);
        
        // Try to record checkpoint on cancelled shipment - should fail
        vm.prank(carrier);
        vm.expectRevert("Cannot record checkpoint for cancelled or delivered shipment");
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", 50);
    }
    
    function testGetShipmentCheckpoints() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoints
        vm.prank(carrier);
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test 1", 50);
        
        vm.prank(carrier);
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 2", "Transit", "Test 2", 60);
        
        // Get checkpoints
        CheckpointsStructures.Checkpoint[] memory checkpoints = shipmentsManagement.getShipmentCheckpoints(shipmentId);
        assertEq(checkpoints.length, 2);
        assertEq(checkpoints[0].location, "Hub 1");
        assertEq(checkpoints[1].location, "Hub 2");
    }
    
    function testReportIncident() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incident
        IncidentStructures.IncidentType incidentType = IncidentStructures.IncidentType.Delay;
        string memory description = "Delivery delayed by 2 hours";
        
        vm.prank(carrier);
        uint256 incidentId = shipmentsManagement.reportIncident(shipmentId, incidentType, description);
        
        // Verify incident was reported
        IncidentStructures.Incident memory incident = shipmentsManagement.getIncident(incidentId);
        assertEq(incident.id, incidentId);
        assertEq(incident.shipmentId, shipmentId);
        assertEq(uint256(incident.incidentType), uint256(incidentType));
        assertEq(incident.reporter, carrier);
        assertEq(incident.description, description);
        assertFalse(incident.resolved);
        
        // Verify incident was added to shipment
        ShipmentStructures.Shipment memory shipment = shipmentsManagement.getShipment(shipmentId);
        assertEq(shipment.incidentIds.length, 1);
        assertEq(shipment.incidentIds[0], incidentId);
    }
    
    function testReportIncidentOnCancelledShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Cancel the shipment
        vm.prank(sender);
        shipmentsManagement.cancelShipment(shipmentId);
        
        // Try to report incident on cancelled shipment - should fail
        vm.prank(carrier);
        vm.expectRevert("Cannot report incident on cancelled shipment");
        shipmentsManagement.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test description");
    }
    
    function testResolveIncident() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incident
        vm.prank(carrier);
        uint256 incidentId = shipmentsManagement.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test description");
        
        // Resolve incident
        vm.prank(carrier);
        shipmentsManagement.resolveIncident(incidentId);
        
        // Verify incident was resolved
        IncidentStructures.Incident memory incident = shipmentsManagement.getIncident(incidentId);
        assertTrue(incident.resolved);
    }
    
    function testResolveAlreadyResolvedIncident() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incident
        vm.prank(carrier);
        uint256 incidentId = shipmentsManagement.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test description");
        
        // Resolve incident first
        vm.prank(carrier);
        shipmentsManagement.resolveIncident(incidentId);
        
        // Try to resolve again - should fail
        vm.prank(carrier);
        vm.expectRevert("Incident already resolved");
        shipmentsManagement.resolveIncident(incidentId);
    }
    
    function testGetShipmentIncidents() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incidents
        vm.prank(carrier);
        shipmentsManagement.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test 1");
        
        vm.prank(carrier);
        shipmentsManagement.reportIncident(shipmentId, IncidentStructures.IncidentType.Damage, "Test 2");
        
        // Get incidents
        IncidentStructures.Incident[] memory incidents = shipmentsManagement.getShipmentIncidents(shipmentId);
        assertEq(incidents.length, 2);
        assertEq(uint256(incidents[0].incidentType), uint256(IncidentStructures.IncidentType.Delay));
        assertEq(uint256(incidents[1].incidentType), uint256(IncidentStructures.IncidentType.Damage));
    }
    
    function testVerifyTemperatureCompliance() public {
        // Create a shipment that requires cold chain
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Vaccine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoints with valid temperatures
        vm.prank(carrier);
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", 50); // 5.0°C
        
        vm.prank(carrier);
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 2", "Transit", "Test", -20); // -2.0°C
        
        // Verify temperature compliance
        bool compliant = shipmentsManagement.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }
    
    function testVerifyTemperatureComplianceInvalid() public {
        // Create a shipment that requires cold chain
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Vaccine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoints with invalid temperatures
        vm.prank(carrier);
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", -60); // -6.0°C (too cold)
        
        // Verify temperature compliance
        bool compliant = shipmentsManagement.verifyTemperatureCompliance(shipmentId);
        assertFalse(compliant);
    }
    
    function testVerifyTemperatureComplianceNoColdChain() public {
        // Create a shipment that does NOT require cold chain
        vm.prank(sender);
        uint256 shipmentId = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", false);
        
        // Record checkpoints with invalid temperatures (should not matter)
        vm.prank(carrier);
        shipmentsManagement.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", -60); // -6.0°C
        
        // Verify temperature compliance
        bool compliant = shipmentsManagement.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }
    
    function testGetActorShipmentsData() public {
        // Create two shipments for different actors
        vm.prank(sender);
        uint256 shipment1Id = shipmentsManagement.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        vm.prank(carrier);
        uint256 shipment2Id = shipmentsManagement.createShipment(recipient, "Vaccine", "Warehouse C", "Hospital D", true);
        
        // Get sender's shipments
        vm.prank(sender);
        ShipmentStructures.Shipment[] memory senderShipments = shipmentsManagement.getActorShipmentsData(0, 10);
        assertEq(senderShipments.length, 1);
        assertEq(senderShipments[0].id, shipment1Id);
        
        // Get carrier's shipments
        vm.prank(carrier);
        ShipmentStructures.Shipment[] memory carrierShipments = shipmentsManagement.getActorShipmentsData(0, 10);
        assertEq(carrierShipments.length, 1);
        assertEq(carrierShipments[0].id, shipment2Id);
    }
}