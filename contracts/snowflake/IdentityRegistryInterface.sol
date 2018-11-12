pragma solidity 0.4.25;


interface IdentityRegistryInterface {
  function isSigned(
    address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s
  ) external view returns (bool);

  function identityExists(uint ein) external view returns (bool);
  function getEIN(address _address) external view returns (uint ein);
  function isResolverFor(uint ein, address resolver) external view returns (bool);
  function createIdentityDelegated(
      address recoveryAddress, address associatedAddress, address[] resolvers,
      uint8 v, bytes32 r, bytes32 s, uint timestamp
  ) external returns (uint ein);
  function addAddressDelegated(
      address approvingAddress, address addressToAdd, uint8[2] v, bytes32[2] r, bytes32[2] s, uint[2] timestamp
  ) external;
  function removeAddressDelegated(address addressToRemove, uint8 v, bytes32 r, bytes32 s, uint timestamp) external;
  function addProvidersFor(uint ein, address[] providers) external;
  function removeProvidersFor(uint ein, address[] providers) external;
  function addResolversFor(uint ein, address[] resolvers) external;
  function removeResolversFor(uint ein, address[] resolvers) external;

  function initiateRecoveryAddressChangeFor(uint ein, address newRecoveryAddress) external;
}
