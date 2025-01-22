/*
    
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
  ██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
  ██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
   ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████
  
  Find any smart contract, and build your project faster: https://www.cookbook.dev
  Twitter: https://twitter.com/cookbook_dev
  Discord: https://discord.gg/cookbookdev
  
  Find this contract on Cookbook: https://www.cookbook.dev/contracts/Uniswap-V3-Periphery/?utm=code
  */
  
  // SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../interfaces/INonfungiblePositionManager.sol';

contract NonfungiblePositionManagerPositionsGasTest {
    INonfungiblePositionManager immutable nonfungiblePositionManager;

    constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    function getGasCostOfPositions(uint256 tokenId) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        nonfungiblePositionManager.positions(tokenId);
        return gasBefore - gasleft();
    }
}
