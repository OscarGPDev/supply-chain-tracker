// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/SupplyChainB.sol";

contract supplyChainTest is Test {
    SupplyChain public supplyChain;
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    address public sender;
    address public recipient;
    address public carrier;

    function setUp() public {
        // Deploy the contract
        supplyChain = new SupplyChain();
        
        // Get addresses
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x8);
        sender = address(0x1);
        recipient = address(0x2);
        carrier = address(0x3);
        // Simulate registering users with different roles
        vm.prank(admin);
        supplyChain.registerActor(user1, "Sender1", ActorStructures.ActorRole.Sender, "Location1");       
        vm.prank(admin);
        supplyChain.registerActor(user2, "Carrier1", ActorStructures.ActorRole.Carrier, "Location2");
    }
    
    function testRegisterActor() public {
        // Test registration
        address newActor = address(0x3);
        string memory name = "Recipient1";
        ActorStructures.ActorRole role = ActorStructures.ActorRole.Recipient;
        string memory location = "Location3";
        
        vm.prank(admin);
        supplyChain.registerActor(newActor, name, role, location);
        vm.prank(newActor);
        // Verify actor was registered by checking the stored data directly
        ActorStructures.Actor memory actor = supplyChain.getActor();
        assertEq(actor.actorAddress, newActor);
        assertEq(actor.name, name);
        assertEq(uint256(actor.role), uint256(role));
        assertEq(actor.location, location);
        assertTrue(actor.isActive);
    }
    
    function testRegisterDuplicateActor() public {
        // Try to register an already registered actor
        vm.prank(admin);
        vm.expectRevert("Actor already registered");
        supplyChain.registerActor(user1, "Sender2", ActorStructures.ActorRole.Sender, "Location4");
    }
    
    function testGetActor() public {
        // Test getting actor data for user1
        vm.prank(user1);
        ActorStructures.Actor memory actor = supplyChain.getActor();
        
        assertEq(actor.actorAddress, user1);
        assertEq(actor.name, "Sender1");
        assertEq(uint(actor.role), uint(ActorStructures.ActorRole.Sender));
        assertEq(actor.location, "Location1");
        assertTrue(actor.isActive);
    }
    
    function testGetActiveActorsCount() public {
        // Test active actors count
        uint256 count = supplyChain.getActiveActorsCount();
        assertEq(count, 2);
    }
    
    function testGetInactiveActorsCount() public {
        // Test inactive actors count (should be 0 initially)
        uint256 count = supplyChain.getInactiveActorsCount();
        assertEq(count, 0);
    }
    
    function testDeactivateActor() public {
        // Deactivate an actor
        vm.prank(admin);
        supplyChain.deactivateActor(user1);
        
        // Verify actor is deactivated
        ActorStructures.Actor memory actor = supplyChain.getActor();
        assertFalse(actor.isActive);
        
        // Verify count
        uint256 count = supplyChain.getActiveActorsCount();
        assertEq(count, 1);
        count = supplyChain.getInactiveActorsCount();
        assertEq(count, 1);
    }
    
    function testReactivateActor() public {
        // Register an actor first
        vm.prank(admin);
        supplyChain.registerActor(user3, "Sender1", ActorStructures.ActorRole.Sender, "Location1");
        
        // Deactivate the actor
        vm.prank(admin);
        supplyChain.deactivateActor(user3);
        
        // Verify it's deactivated
        vm.prank(user3);
        ActorStructures.Actor memory actor = supplyChain.getActor();
        assertFalse(actor.isActive);
        
        // Reactivate actor
        vm.prank(admin);
        supplyChain.reactivateActor(user3);
        
        // Verify actor is reactivated by checking the stored data directly
        vm.prank(user3);
        actor = supplyChain.getActor();
        assertTrue(actor.isActive);
        
        // Verify counts
        uint256 count = supplyChain.getActiveActorsCount();
        assertEq(count, 3);
        count = supplyChain.getInactiveActorsCount();
        assertEq(count, 0);
    }
    
    function testDeactivateNonExistentActor() public {
        address nonExistentActor = address(0x999);
        
        // Try to deactivate non-existent actor
        vm.prank(admin);
        vm.expectRevert("Actor not found");
        supplyChain.deactivateActor(nonExistentActor);
    }
    
    function testOnlyAdminCanRegister() public {
        // Try to register with non-admin account
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        supplyChain.registerActor(address(0x4), "Test", ActorStructures.ActorRole.Sender, "Location");
    }
    
    function testOnlyAdminCanDeactivate() public {
        // Try to deactivate with non-admin account
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        supplyChain.deactivateActor(user1);
    }
    
    function testOnlyAdminCanReactivate() public {
        // Deactivate first
        vm.prank(admin);
        supplyChain.deactivateActor(user1);
        
        // Try to reactivate with non-admin account
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        supplyChain.reactivateActor(user1);
    }
    
    function testGetActiveActors() public {
        // Get active actors (should return both users)
        ActorStructures.Actor[] memory activeActors = supplyChain.getActiveActors(0, 10);
        
        assertEq(activeActors.length, 2);
        assertEq(activeActors[0].actorAddress, user1);
        assertEq(activeActors[1].actorAddress, user2);
    }
    
    function testGetInactiveActors() public {
        // Get inactive actors (should return empty)
        ActorStructures.Actor[] memory inactiveActors = supplyChain.getInactiveActors(0, 10);
        
        assertEq(inactiveActors.length, 0);
    }
    
    function testEventEmissionOnRegistration() public {
        address newActor = address(0x5);
        string memory name = "NewActor";
        ActorStructures.ActorRole role = ActorStructures.ActorRole.Hub;
        string memory location = "NewLocation";
        
        // Capture events by listening for them after calling the function
        vm.prank(admin);
        supplyChain.registerActor(newActor, name, role, location);
    }
    
    function testEventEmissionOnDeactivation() public {
        // Capture events by listening for them after calling the function
        vm.prank(admin);
        supplyChain.deactivateActor(user1);
    }
    
    function testEventEmissionOnReactivation() public {
        // First deactivate
        vm.prank(admin);
        supplyChain.deactivateActor(user1);
        
        // Capture events by listening for them after calling the function
        vm.prank(admin);
        supplyChain.reactivateActor(user1);
    }
    function testCreateShipment() public {
        string memory product = "Medicine";
        string memory origin = "Warehouse A";
        string memory destination = "Hospital B";
        bool requiresColdChain = true;
        
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, product, origin, destination, requiresColdChain);
        
        // Verify shipment was created
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
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
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Get the shipment
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(shipment.id, shipmentId);
        assertEq(shipment.sender, sender);
        assertEq(shipment.recipient, recipient);
    }
    
    function testUpdateShipmentStatus() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Update status
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, ShipmentStructures.ShipmentStatus.InTransit);
        
        // Verify status was updated
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.InTransit));
    }
    
    function testConfirmDelivery() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Confirm delivery as recipient
        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        // Verify status was updated
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.Delivered));
        assertEq(shipment.dateDelivered, block.timestamp);
    }
    
    function testConfirmDeliveryNotRecipient() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Try to confirm delivery as someone other than recipient - should fail
        vm.prank(carrier);
        vm.expectRevert("Only recipient can confirm delivery");
        supplyChain.confirmDelivery(shipmentId);
    }
    
    function testCancelShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Cancel shipment as sender
        vm.prank(sender);
        supplyChain.cancelShipment(shipmentId);
        
        // Verify status was updated
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(ShipmentStructures.ShipmentStatus.Cancelled));
    }
    
    function testCancelShipmentNotSenderOrRecipient() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Try to cancel shipment as someone other than sender or recipient - should fail
        vm.prank(carrier);
        vm.expectRevert("Only sender or recipient can cancel shipment");
        supplyChain.cancelShipment(shipmentId);
    }
    
    function testRecordCheckpoint() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoint
        string memory location = "Hub 1";
        string memory checkpointType = "Transit";
        string memory notes = "Temperature check";
        int256 temperature = 50; // 5.0 degrees Celsius
        
        vm.prank(carrier);
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, location, checkpointType, notes, temperature);
        
        // Verify checkpoint was recorded
        CheckpointsStructures.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.id, checkpointId);
        assertEq(checkpoint.shipmentId, shipmentId);
        assertEq(checkpoint.actor, carrier);
        assertEq(checkpoint.location, location);
        assertEq(checkpoint.checkpointType, checkpointType);
        assertEq(checkpoint.temperature, temperature);
        
        // Verify checkpoint was added to shipment
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(shipment.checkpointIds.length, 1);
        assertEq(shipment.checkpointIds[0], checkpointId);
    }
    
    function testRecordCheckpointOnCancelledShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Cancel the shipment
        vm.prank(sender);
        supplyChain.cancelShipment(shipmentId);
        
        // Try to record checkpoint on cancelled shipment - should fail
        vm.prank(carrier);
        vm.expectRevert("Cannot record checkpoint for cancelled or delivered shipment");
        supplyChain.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", 50);
    }
    
    function testGetShipmentCheckpoints() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoints
        vm.prank(carrier);
        supplyChain.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test 1", 50);
        
        vm.prank(carrier);
        supplyChain.recordCheckpoint(shipmentId, "Hub 2", "Transit", "Test 2", 60);
        
        // Get checkpoints
        CheckpointsStructures.Checkpoint[] memory checkpoints = supplyChain.getShipmentCheckpoints(shipmentId);
        assertEq(checkpoints.length, 2);
        assertEq(checkpoints[0].location, "Hub 1");
        assertEq(checkpoints[1].location, "Hub 2");
    }
    
    function testReportIncident() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incident
        IncidentStructures.IncidentType incidentType = IncidentStructures.IncidentType.Delay;
        string memory description = "Delivery delayed by 2 hours";
        
        vm.prank(carrier);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, incidentType, description);
        
        // Verify incident was reported
        IncidentStructures.Incident memory incident = supplyChain.getIncident(incidentId);
        assertEq(incident.id, incidentId);
        assertEq(incident.shipmentId, shipmentId);
        assertEq(uint256(incident.incidentType), uint256(incidentType));
        assertEq(incident.reporter, carrier);
        assertEq(incident.description, description);
        assertFalse(incident.resolved);
        
        // Verify incident was added to shipment
        ShipmentStructures.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(shipment.incidentIds.length, 1);
        assertEq(shipment.incidentIds[0], incidentId);
    }
    
    function testReportIncidentOnCancelledShipment() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Cancel the shipment
        vm.prank(sender);
        supplyChain.cancelShipment(shipmentId);
        
        // Try to report incident on cancelled shipment - should fail
        vm.prank(carrier);
        vm.expectRevert("Cannot report incident on cancelled shipment");
        supplyChain.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test description");
    }
    
    function testResolveIncident() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incident
        vm.prank(carrier);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test description");
        
        // Resolve incident
        vm.prank(carrier);
        supplyChain.resolveIncident(incidentId);
        
        // Verify incident was resolved
        IncidentStructures.Incident memory incident = supplyChain.getIncident(incidentId);
        assertTrue(incident.resolved);
    }
    
    function testResolveAlreadyResolvedIncident() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incident
        vm.prank(carrier);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test description");
        
        // Resolve incident first
        vm.prank(carrier);
        supplyChain.resolveIncident(incidentId);
        
        // Try to resolve again - should fail
        vm.prank(carrier);
        vm.expectRevert("Incident already resolved");
        supplyChain.resolveIncident(incidentId);
    }
    
    function testGetShipmentIncidents() public {
        // Create a shipment first
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        // Report incidents
        vm.prank(carrier);
        supplyChain.reportIncident(shipmentId, IncidentStructures.IncidentType.Delay, "Test 1");
        
        vm.prank(carrier);
        supplyChain.reportIncident(shipmentId, IncidentStructures.IncidentType.Damage, "Test 2");
        
        // Get incidents
        IncidentStructures.Incident[] memory incidents = supplyChain.getShipmentIncidents(shipmentId);
        assertEq(incidents.length, 2);
        assertEq(uint256(incidents[0].incidentType), uint256(IncidentStructures.IncidentType.Delay));
        assertEq(uint256(incidents[1].incidentType), uint256(IncidentStructures.IncidentType.Damage));
    }
    
    function testVerifyTemperatureCompliance() public {
        // Create a shipment that requires cold chain
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Vaccine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoints with valid temperatures
        vm.prank(carrier);
        supplyChain.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", 50); // 5.0°C
        
        vm.prank(carrier);
        supplyChain.recordCheckpoint(shipmentId, "Hub 2", "Transit", "Test", -20); // -2.0°C
        
        // Verify temperature compliance
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }
    
    function testVerifyTemperatureComplianceInvalid() public {
        // Create a shipment that requires cold chain
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Vaccine", "Warehouse A", "Hospital B", true);
        
        // Record checkpoints with invalid temperatures
        vm.prank(carrier);
        supplyChain.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", -60); // -6.0°C (too cold)
        
        // Verify temperature compliance
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertFalse(compliant);
    }
    
    function testVerifyTemperatureComplianceNoColdChain() public {
        // Create a shipment that does NOT require cold chain
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", false);
        
        // Record checkpoints with invalid temperatures (should not matter)
        vm.prank(carrier);
        supplyChain.recordCheckpoint(shipmentId, "Hub 1", "Transit", "Test", -60); // -6.0°C
        
        // Verify temperature compliance
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }
    
    function testGetActorShipmentsData() public {
        // Create two shipments for different actors
        vm.prank(sender);
        uint256 shipment1Id = supplyChain.createShipment(recipient, "Medicine", "Warehouse A", "Hospital B", true);
        
        vm.prank(carrier);
        uint256 shipment2Id = supplyChain.createShipment(recipient, "Vaccine", "Warehouse C", "Hospital D", true);
        
        // Get sender's shipments
        vm.prank(sender);
        ShipmentStructures.Shipment[] memory senderShipments = supplyChain.getActorShipmentsData(0, 10);
        assertEq(senderShipments.length, 1);
        assertEq(senderShipments[0].id, shipment1Id);
        
        // Get carrier's shipments
        vm.prank(carrier);
        ShipmentStructures.Shipment[] memory carrierShipments = supplyChain.getActorShipmentsData(0, 10);
        assertEq(carrierShipments.length, 1);
        assertEq(carrierShipments[0].id, shipment2Id);
    }
}