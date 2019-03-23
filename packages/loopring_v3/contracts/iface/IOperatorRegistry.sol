/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.5.2;


/// @title IOperatorRegistry
/// @author Brecht Devos - <brecht@loopring.org>
contract IOperatorRegistry
{
    event OperatorRegistered(
        address operator,
        uint32 operatorID
    );

    event OperatorUnregistered(
        address operator,
        uint32 operatorID
    );

    function createNewState(
        address owner,
        bool closedOperatorRegistering
        )
        external;

    function getActiveOperatorID(
        uint32 stateID
        )
        external
        view
        returns (uint32);

    function getOperatorOwner(
        uint32 stateID,
        uint32 operatorID
        )
        external
        view
        returns (address payable owner);

    function ejectOperator(
        uint32 stateID,
        uint32 operatorID
        )
        external;
}