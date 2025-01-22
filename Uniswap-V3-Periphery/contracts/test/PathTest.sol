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

import '../libraries/Path.sol';

contract PathTest {
    function hasMultiplePools(bytes memory path) public pure returns (bool) {
        return Path.hasMultiplePools(path);
    }

    function decodeFirstPool(bytes memory path)
        public
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        return Path.decodeFirstPool(path);
    }

    function getFirstPool(bytes memory path) public pure returns (bytes memory) {
        return Path.getFirstPool(path);
    }

    function skipToken(bytes memory path) public pure returns (bytes memory) {
        return Path.skipToken(path);
    }

    // gas funcs
    function getGasCostOfDecodeFirstPool(bytes memory path) public view returns (uint256) {
        uint256 gasBefore = gasleft();
        Path.decodeFirstPool(path);
        return gasBefore - gasleft();
    }
}
