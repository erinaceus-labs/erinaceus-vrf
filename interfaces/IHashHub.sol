// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
/**
 * @title HashHub
 * @notice This contract provides a way to access blockhashes older than
 *   the 256 block limit imposed by the BLOCKHASH opcode.
 *   You may assume that any blockhash stored by the contract is correct.
 *   Note that the contract depends on the format of serialized Ethereum
 *   blocks. If a future hardfork of Ethereum changes that format, the
 *   logic in this contract may become incorrect and an updated version
 *   would have to be deployed.
 */
interface IHashHub {  
  function store(uint256 n) external;

  function requestBlockhash(uint256 _blockNumber) external payable;
  
  function claimRewardsForUnregisteredBlocks(uint256[] memory _blocks) external;
  
  function getBlockhash(uint256 n) external view returns (bytes32);
  
  function rewardForStoring(uint256) external view returns(uint256);

  function usersRequestedBlocks(address) external view returns(uint256[] memory);

  function providedRewards(address, uint256) external view returns(uint256);
}
