// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/ActorsManagement.sol";
import "../src/Interfaces/IActorsManagement.sol";

contract ActorsManagementTest is Test {
    ActorsManagement public actorsManagement;
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    
    function setUp() public {
        // Deploy the contract
        actorsManagement = new ActorsManagement();
        
        // Get addresses
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x8);
        // Simulate registering users with different roles
        vm.prank(admin);
        actorsManagement.registerActor(user1, "Sender1", ActorStructures.ActorRole.Sender, "Location1");
        
        vm.prank(admin);
        actorsManagement.registerActor(user2, "Carrier1", ActorStructures.ActorRole.Carrier, "Location2");
    }
    
    function testRegisterActor() public {
        // Test registration
        address newActor = address(0x3);
        string memory name = "Recipient1";
        ActorStructures.ActorRole role = ActorStructures.ActorRole.Recipient;
        string memory location = "Location3";
        
        vm.prank(admin);
        actorsManagement.registerActor(newActor, name, role, location);
        vm.prank(newActor);
        // Verify actor was registered by checking the stored data directly
        ActorStructures.Actor memory actor = actorsManagement.getActor();
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
        actorsManagement.registerActor(user1, "Sender2", ActorStructures.ActorRole.Sender, "Location4");
    }
    
    function testGetActor() public {
        // Test getting actor data for user1
        vm.prank(user1);
        ActorStructures.Actor memory actor = actorsManagement.getActor();
        
        assertEq(actor.actorAddress, user1);
        assertEq(actor.name, "Sender1");
        assertEq(uint(actor.role), uint(ActorStructures.ActorRole.Sender));
        assertEq(actor.location, "Location1");
        assertTrue(actor.isActive);
    }
    
    function testGetActiveActorsCount() public {
        // Test active actors count
        uint256 count = actorsManagement.getActiveActorsCount();
        assertEq(count, 2);
    }
    
    function testGetInactiveActorsCount() public {
        // Test inactive actors count (should be 0 initially)
        uint256 count = actorsManagement.getInactiveActorsCount();
        assertEq(count, 0);
    }
    
    function testDeactivateActor() public {
        // Deactivate an actor
        vm.prank(admin);
        actorsManagement.deactivateActor(user1);
        
        // Verify actor is deactivated
        ActorStructures.Actor memory actor = actorsManagement.getActor();
        assertFalse(actor.isActive);
        
        // Verify count
        uint256 count = actorsManagement.getActiveActorsCount();
        assertEq(count, 1);
        count = actorsManagement.getInactiveActorsCount();
        assertEq(count, 1);
    }
    
    function testReactivateActor() public {
        // Register an actor first
        vm.prank(admin);
        actorsManagement.registerActor(user3, "Sender1", ActorStructures.ActorRole.Sender, "Location1");
        
        // Deactivate the actor
        vm.prank(admin);
        actorsManagement.deactivateActor(user3);
        
        // Verify it's deactivated
        vm.prank(user3);
        ActorStructures.Actor memory actor = actorsManagement.getActor();
        assertFalse(actor.isActive);
        
        // Reactivate actor
        vm.prank(admin);
        actorsManagement.reactivateActor(user3);
        
        // Verify actor is reactivated by checking the stored data directly
        vm.prank(user3);
        actor = actorsManagement.getActor();
        assertTrue(actor.isActive);
        
        // Verify counts
        uint256 count = actorsManagement.getActiveActorsCount();
        assertEq(count, 3);
        count = actorsManagement.getInactiveActorsCount();
        assertEq(count, 0);
    }
    
    function testDeactivateNonExistentActor() public {
        address nonExistentActor = address(0x999);
        
        // Try to deactivate non-existent actor
        vm.prank(admin);
        vm.expectRevert("Actor not found");
        actorsManagement.deactivateActor(nonExistentActor);
    }
    
    function testOnlyAdminCanRegister() public {
        // Try to register with non-admin account
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        actorsManagement.registerActor(address(0x4), "Test", ActorStructures.ActorRole.Sender, "Location");
    }
    
    function testOnlyAdminCanDeactivate() public {
        // Try to deactivate with non-admin account
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        actorsManagement.deactivateActor(user1);
    }
    
    function testOnlyAdminCanReactivate() public {
        // Deactivate first
        vm.prank(admin);
        actorsManagement.deactivateActor(user1);
        
        // Try to reactivate with non-admin account
        vm.prank(user1);
        vm.expectRevert("Only admin can call this function");
        actorsManagement.reactivateActor(user1);
    }
    
    function testGetActiveActors() public {
        // Get active actors (should return both users)
        ActorStructures.Actor[] memory activeActors = actorsManagement.getActiveActors(0, 10);
        
        assertEq(activeActors.length, 2);
        assertEq(activeActors[0].actorAddress, user1);
        assertEq(activeActors[1].actorAddress, user2);
    }
    
    function testGetInactiveActors() public {
        // Get inactive actors (should return empty)
        ActorStructures.Actor[] memory inactiveActors = actorsManagement.getInactiveActors(0, 10);
        
        assertEq(inactiveActors.length, 0);
    }
    
    function testEventEmissionOnRegistration() public {
        address newActor = address(0x5);
        string memory name = "NewActor";
        ActorStructures.ActorRole role = ActorStructures.ActorRole.Hub;
        string memory location = "NewLocation";
        
        // Capture events
        vm.expectEmit(true, true, true, true);
        emit IActorsManagement.ActorRegistered(newActor, name, role);
        
        vm.prank(admin);
        actorsManagement.registerActor(newActor, name, role, location);
    }
    
    function testEventEmissionOnDeactivation() public {
        // Capture events
        vm.expectEmit(true, true, true, true);
        emit IActorsManagement.ActorDeactivated(user1);
        
        vm.prank(admin);
        actorsManagement.deactivateActor(user1);
    }
    
    function testEventEmissionOnReactivation() public {
        // First deactivate
        vm.prank(admin);
        actorsManagement.deactivateActor(user1);
        
        // Capture events
        vm.expectEmit(true, true, true, true);
        emit IActorsManagement.ActorReactivated(user1);
        
        vm.prank(admin);
        actorsManagement.reactivateActor(user1);
    }
}