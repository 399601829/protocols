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
pragma solidity 0.5.7;

import "../lib/Ownable.sol";

/// @title IOedax
/// @author Daniel Wang  - <daniel@loopring.org>
contract IOedax is Ownable
{
    address[] auctions;

    // auction_address => auction_id
    mapping (address => uint) auctionIdMap;
    // auction_creator =>  list of his auctions
    mapping (address => address[]) creatorAuctions;

    // user_address => auction_address => participated?
    mapping (address => mapping (address => bool)) particationMap;

    // user_address => list_of_auctions_participated
    mapping (address => address[]) userAuctions;

    // auction_address => list_of_auction_users
    mapping (address => address[]) auctionUsers;

    mapping (address => uint32) tokenRankMap;

    event SettingsUpdated(
    );

    event TokenRankUpdated(
        address token,
        uint32  rank
    );

    event AuctionCreated (
        uint    auctionId,
        address auctionAddr
    );

    function updateSettings(
        uint16 _settleGracePeriodMinutes,
        uint16 _minDurationMinutes,
        uint16 _maxDurationMinutes
        )
        external;

    function setTokenRank(
        address token,
        uint32  rank
        )
        public;

    function createAuction(
        uint    curveId,
        address askToken,
        address bidToken,
        uint64  P, // target price
        uint64  S, // price scale
        uint8   M, // price factor
        uint    T
        )
        public
        payable
        returns (address auction);

    function logParticipation(
        address user
        )
        public;

    function transferToken(
        address token,
        address user,
        uint    amount
        )
        public
        returns (bool success);
}