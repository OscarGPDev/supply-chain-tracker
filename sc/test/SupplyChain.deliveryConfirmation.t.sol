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


    // Tests de confirmación de entrega
    function testConfirmDeliveryByRecipient() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.Delivered));
    }

    function testOnlyRecipientCanConfirmDelivery() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender); // Try to confirm as sender
        vm.expectRevert();
        supplyChain.confirmDelivery(shipmentId);
    }

    function testDeliveryUpdatesTimestamp() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient,"Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        uint256 beforeTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1); // Ensure timestamp changes
        
        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertTrue(shipment.dateDelivered > beforeTimestamp);
    }
    function testCannotConfirmDeliveryTwice() public {        
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        vm.prank(recipient);
        vm.expectRevert();
        supplyChain.confirmDelivery(shipmentId);
    }


}
