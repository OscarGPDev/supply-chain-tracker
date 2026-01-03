// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
import "../Structs/ActorStructures.sol";

interface IActorsManagement {    
    event ActorRegistered(
        address indexed actorAddress,
        string name,
        ActorStructures.ActorRole role
    );
    event ActorDeactivated(address indexed actorAddress);
    event ActorReactivated(address indexed actorAddress);

    // Gestión de Actores
    function registerActor(
        address _actorAddress,
        string memory _name,
        ActorStructures.ActorRole _role,
        string memory _location
    ) external;

    function getActiveActors(
        uint256 _page,
        uint256 _pageSize
    ) external view  returns (ActorStructures.Actor[] memory);

    function getInactiveActors(
        uint256 _page,
        uint256 _pageSize
    ) external view  returns (ActorStructures.Actor[] memory);

    function getActor() external view returns (ActorStructures.Actor memory);

    function getActiveActorsCount() external view returns (uint256);

    function getInactiveActorsCount() external view returns (uint256);

    function deactivateActor(address _actorAddress) external;

    function reactivateActor(address _actorAddress) external;
}
