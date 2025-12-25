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

    // Tests de temperatura
    function testVerifyTemperatureComplianceValid() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "New York", "Los Angeles", true);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Location 1", "Pickup", "", 50); // 5°C
        
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }

    function testVerifyTemperatureComplianceViolation() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "New York", "Los Angeles", true);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Location 1", "Pickup", "", -100); // -10°C (below limit)
        
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertFalse(compliant);
    }

    function testColdChainMonitoring() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "New York", "Los Angeles", true);

        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Warehouse", "Pickup", "", 50); // 5°C
        
        vm.prank(sender);
        supplyChain.recordCheckpoint(shipmentId, "Transport", "Transit", "", 100); // 10°C
        
        bool compliant = supplyChain.verifyTemperatureCompliance(shipmentId);
        assertTrue(compliant);
    }
}
