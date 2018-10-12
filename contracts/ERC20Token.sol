pragma solidity 0.4.24;


/**
 * @title ERC20Token Interface
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20Token {
  function name() public view returns (string);
  function symbol() public view returns (string);
  function decimals() public view returns (uint);
  function totalSupply() public view returns (uint);
  function balanceOf(address account) public view returns (uint);
  function transfer(address to, uint amount) public returns (bool);
  function transferFrom(address from, address to, uint amount) public returns (bool);
  function approve(address spender, uint amount) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint);
}
