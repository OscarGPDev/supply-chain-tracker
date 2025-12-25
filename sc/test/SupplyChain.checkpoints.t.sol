// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/SupplyChain.sol";

contract LogisticsTrackingTest is Test {
    SupplyChain supplyChain;
    address sender = address(0x2);
    address carrier = address(0x3);
    address hub = address(0x4);
    address recipient = address(0x5);
    address inspector = address(0x6);

    function setUp() public {
        supplyChain = new SupplyChain();
    }


    // Tests de checkpoints
    function testRecordPickupCheckpoint() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, "New York Warehouse", "Pickup", "Package picked up", 200);
        
        assertEq(checkpointId, 1);
        
        SupplyChain.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.shipmentId, shipmentId);
        assertEq(checkpoint.actor, sender);
        assertEq(checkpoint.location, "New York Warehouse");
        assertEq(checkpoint.checkpointType, "Pickup");
        assertEq(checkpoint.temperature, 200);
    }

    function testRecordHubCheckpoint() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(hub, "Hub", SupplyChain.ActorRole.Hub, "Chicago");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(hub);
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, "Chicago Hub", "Hub", "Package at hub", 150);
        
        SupplyChain.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.checkpointType, "Hub");
    }

    function testRecordTransitCheckpoint() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(carrier, "Carrier", SupplyChain.ActorRole.Carrier, "Transport");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(carrier);
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, "On Route", "Transit", "In transit", 100);
        
        SupplyChain.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.checkpointType, "Transit");
    }

    function testRecordDeliveryCheckpoint() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(recipient);
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, "Los Angeles Delivery", "Delivery", "Delivered to recipient", 250);
        
        SupplyChain.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.checkpointType, "Delivery");
    }

    function testRecordCheckpointWithTemperature() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, "Test Location", "Pickup", "Test", 180);
        
        SupplyChain.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.temperature, 180);
    }

    function testGetShipmentCheckpoints() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Location 1", "Pickup", "", 0);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Location 2", "Transit", "", 0);
        
        SupplyChain.Checkpoint[] memory checkpoints = supplyChain.getShipmentCheckpoints(shipmentId);
        assertEq(checkpoints.length, 2);
    }

    function testCheckpointTimeline() public {
        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Location 1", "Pickup", "", 0);
        
        vm.warp(block.timestamp + 3600); // Advance time by 1 hour
        
        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Location 2", "Transit", "", 0);
        
        SupplyChain.Checkpoint[] memory checkpoints = supplyChain.getShipmentCheckpoints(shipmentId);
        assertEq(checkpoints.length, 2);
        assertTrue(checkpoints[1].timestamp > checkpoints[0].timestamp);
    }


}
