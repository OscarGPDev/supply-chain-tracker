// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/SupplyChain.sol";

contract LogisticsTrackingTest is Test {
    SupplyChain supplyChain;
    address admin = address(0x1);
    address sender = address(0x2);
    address carrier = address(0x3);
    address hub = address(0x4);
    address recipient = address(0x5);
    address inspector = address(0x6);

    function setUp() public {
        
        supplyChain = new SupplyChain();
        admin = msg.sender;
        //supplyChain.registerActor("Admin", SupplyChain.ActorRole.None, "Headquarters");
    }


    // Tests de casos edge
    function testMultipleCheckpointsForSameShipment() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        for (uint256 i = 0; i < 10; i++) {
            vm.prank(sender);
            supplyChain.recordCheckpoint(shipmentId, string(abi.encodePacked("Location ", uint256(i))), "Transit", "", 0);
        }
        
        SupplyChain.Checkpoint[] memory checkpoints = supplyChain.getShipmentCheckpoints(shipmentId);
        assertEq(checkpoints.length, 10);
    }

    function testShipmentWithMultipleIncidents() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Delay, "Delayed");
        
        vm.prank(sender);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Damage, "Damaged");
        
        vm.prank(sender);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Lost, "Lost");
        
        SupplyChain.Incident[] memory incidents = supplyChain.getShipmentIncidents(shipmentId);
        assertEq(incidents.length, 3);
    }

    function testEmptyCheckpointNotes() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        // The getCheckpoint function seems to be using a global counter instead of a shipment-specific one.
        uint256 checkpointId = supplyChain.recordCheckpoint(shipmentId, "Location", "Pickup", "", 0);
        
        SupplyChain.Checkpoint memory checkpoint = supplyChain.getCheckpoint(checkpointId);
        assertEq(checkpoint.notes, "");
    }


}
