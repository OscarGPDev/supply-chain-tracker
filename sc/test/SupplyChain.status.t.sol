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

    // Tests de actualización de estado
    function testUpdateStatusToInTransit() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.InTransit));
    }

    function testUpdateStatusToAtHub() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(hub, "Hub", SupplyChain.ActorRole.Hub, "Chicago");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(hub);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.AtHub);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.AtHub));
    }

    function testUpdateStatusToOutForDelivery() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.OutForDelivery);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.OutForDelivery));
    }

    function testUpdateStatusToDelivered() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.Delivered);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.Delivered));
    }

    function testStatusChangeEmitsEvent() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.expectEmit(true, true, true, true);
        emit SupplyChain.ShipmentStatusChanged(shipmentId, SupplyChain.ShipmentStatus.InTransit);
        
        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);
    }
}
