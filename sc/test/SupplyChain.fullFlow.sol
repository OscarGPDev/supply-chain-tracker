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
    address hub1 = address(0x7);
    address hub2 = address(0x8);

    function setUp() public {
        
        supplyChain = new SupplyChain();
        admin = msg.sender;
        //supplyChain.registerActor("Admin", SupplyChain.ActorRole.None, "Headquarters");
    }

    // Tests de flujo completo
    function testCompleteShippingFlow() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Warehouse", "Pickup", "Package picked up", 0);
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);
        
        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Hub 1", "Hub", "At hub", 0);
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.AtHub);
        
        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Delivery Truck", "Transit", "In transit", 0);
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.OutForDelivery);
        
        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.Delivered));
    }
function testPharmaceuticalColdChainFlow() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "New York", "Los Angeles", true);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Warehouse", "Pickup", "Package picked up", 50); // 5°C
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);
        
        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Transport Truck", "Transit", "In transit", 80); // 8°C
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.OutForDelivery);
        
        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }

    function testMultiHubLogisticsFlow() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");
        supplyChain.registerActor(hub1, "Hub 1", SupplyChain.ActorRole.Hub, "Chicago");
        supplyChain.registerActor(hub2, "Hub 2", SupplyChain.ActorRole.Hub, "Denver");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Warehouse", "Pickup", "Package picked up", 0);
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);
        
        vm.prank(hub1); // Hub 1
        supplyChain.recordCheckpoint(shipmentId, "Chicago Hub", "Hub", "At Chicago hub", 0);
        
        vm.prank(hub1); // Hub 1
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.AtHub);
        
        vm.prank(hub2); // Hub 2
        supplyChain.recordCheckpoint(shipmentId, "Denver Hub", "Hub", "At Denver hub", 0);
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);
        
        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Delivery Truck", "Transit", "In transit to destination", 0);
        
        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.Delivered));
    }

}
