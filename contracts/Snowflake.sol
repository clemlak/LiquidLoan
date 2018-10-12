pragma solidity 0.4.24;


contract Snowflake {
  function withdrawFrom(string hydroIdFrom, address to, uint amount) public returns (bool);
  function getHydroId(address _address) public view returns (string hydroId);
}
