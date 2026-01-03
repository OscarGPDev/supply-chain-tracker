// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
import "./Structs/ActorStructures.sol";
import "./Interfaces/IActorsManagement.sol";

contract ActorsManagement is IActorsManagement {
    address private admin;
    mapping(address => ActorStructures.Actor) public actors;
    address[] private registeredActiveUsers;
    address[] private registeredInactiveUsers;
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    
    // Gestión de Actores
    function registerActor(address _actorAddress,string memory _name, ActorStructures.ActorRole _role, string memory _location) public onlyAdmin {
        require(actors[_actorAddress].actorAddress == address(0), "Actor already registered");
        
        actors[_actorAddress] = ActorStructures.Actor({
            actorAddress: _actorAddress,
            name: _name,
            role: _role,
            location: _location,
            isActive: true
        });
        
        registeredActiveUsers.push(_actorAddress);
        emit ActorRegistered(_actorAddress, _name, _role);
    }
    function getActiveActors(uint256 _page, uint256 _pageSize) public view onlyAdmin returns (ActorStructures.Actor[] memory) {
        uint256 startIndex = _page * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        if (endIndex > registeredActiveUsers.length) {
            endIndex = registeredActiveUsers.length;
        }
        
        ActorStructures.Actor[] memory result = new ActorStructures.Actor[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = actors[registeredActiveUsers[i]];
        }
        return result;
    }
    function getInactiveActors(uint256 _page, uint256 _pageSize) public view onlyAdmin returns (ActorStructures.Actor[] memory) {
        uint256 startIndex = _page * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        if (endIndex > registeredInactiveUsers.length) {
            endIndex = registeredInactiveUsers.length;
        }
        
        ActorStructures.Actor[] memory result = new ActorStructures.Actor[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = actors[registeredInactiveUsers[i]];
        }
        return result;
    }
    function isAdmin() public view returns (bool) {
        return msg.sender==admin;
    }
    function getActor() public view returns (ActorStructures.Actor memory) {
        return actors[msg.sender];
    }
    function getActiveActorsCount() public view returns (uint256) {
        return registeredActiveUsers.length;
    }
    function getInactiveActorsCount() public view returns (uint256) {
        return registeredInactiveUsers.length;
    }
    function deactivateActor(address _actorAddress) public onlyAdmin {
        require(actors[_actorAddress].actorAddress != address(0), "Actor not found");
        require(actors[_actorAddress].isActive, "Actor already deactivated");
        
        actors[_actorAddress].isActive = false;
        
        // Remove from active users array
        for (uint256 i = 0; i < registeredActiveUsers.length; i++) {
            if (registeredActiveUsers[i] == _actorAddress) {
                registeredActiveUsers[i] = registeredActiveUsers[registeredActiveUsers.length - 1];
                registeredActiveUsers.pop();
                break;
            }
        }
        
        // Add to inactive users array
        registeredInactiveUsers.push(_actorAddress);
        emit ActorDeactivated(_actorAddress);
    }
    function reactivateActor(address _actorAddress) public onlyAdmin {
        require(actors[_actorAddress].actorAddress != address(0), "Actor not found");
        require(!actors[_actorAddress].isActive, "Actor already active");
        
        actors[_actorAddress].isActive = true;
        
        // Remove from inactive users array
        for (uint256 i = 0; i < registeredInactiveUsers.length; i++) {
            if (registeredInactiveUsers[i] == _actorAddress) {
                registeredInactiveUsers[i] = registeredInactiveUsers[registeredInactiveUsers.length - 1];
                registeredInactiveUsers.pop();
                break;
            }
        }
        
        // Add to active users array
        registeredActiveUsers.push(_actorAddress);
        emit ActorReactivated(_actorAddress);
    }
}