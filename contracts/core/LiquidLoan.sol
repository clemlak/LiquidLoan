/* solhint-disable not-rely-on-time, function-max-lines */

pragma solidity 0.4.25;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../snowflake/SnowflakeResolver.sol";
import "../snowflake/IdentityRegistryInterface.sol";
import "../snowflake/Snowflake.sol";


/**
 * @title Base contract for LiquidLoan
 * @dev P2P crypto lending dApp built into the Snowflake dApp store (Proof of concept)
 * @author Clemlak https://github.com/clemlak
 */
contract LiquidLoan is SnowflakeResolver {
  constructor() public {
    snowflakeName = "LiquidLoan";
    snowflakeDescription = "P2P crypto lending";
    snowflakeAddress = 0x9b4af5482c91de824E47a13087b1787048A5a518;

    callOnSignUp = false;
    callOnRemoval = false;
  }

  address private identityRegistryAddress = 0xC4B6CC71A8EAF9B5446F16765e86B8D333C43F9b;

  uint256 private snowflakeOwnerId = 4;

  uint16 private fees = 150;

  struct User {
    uint256 currentDebt;
    uint256 lent;
    uint256 borrowed;
    uint256 reimbursed;
  }

  mapping (uint256 => User) private users;

  enum Status { Open, Ongoing, Closed, Confronted }

  struct Loan {
    uint256 amount;
    uint256 currentDebt;
    Status status;
    uint16 rate;
    uint32 deadline;
    uint256 borrower;
    uint256 lender;
  }

  Loan[] private loans;

  mapping (uint256 => uint256[]) private lendersToLoans;
  mapping (uint256 => uint256[]) private borrowersToLoans;

  event LogLoanRequested(
    uint256 loanId,
    uint256 borrower
  );

  event LogLoanAccepted(
    uint256 loanId,
    uint256 borrower,
    uint256 lender
  );

  event LogLoanReimbursed(
    uint256 loandId,
    uint256 amount
  );

  event LogLoanClosed(
    uint256 loanId
  );

  function requestLoan(uint256 amount, uint16 rate, uint32 deadline) external {
    IdentityRegistryInterface identity = IdentityRegistryInterface(identityRegistryAddress);
    uint256 hydroId = identity.getEIN(msg.sender);

    uint256 loanId = loans.push(
      Loan({
        amount: amount,
        currentDebt: 0,
        rate: rate,
        deadline: deadline,
        status: Status.Open,
        borrower: hydroId,
        lender: 0
      })
    ) - 1;

    borrowersToLoans[hydroId].push(loanId);

    emit LogLoanRequested(loanId, loans[loanId].borrower);
  }

  function lend(uint256 loanId) external {
    Snowflake snowflake = Snowflake(snowflakeAddress);

    IdentityRegistryInterface identity = IdentityRegistryInterface(identityRegistryAddress);
    uint256 hydroId = identity.getEIN(msg.sender);

    require(loans[loanId].status == Status.Open, "Loan is not open");

    require(
      loans[loanId].borrower != hydroId,
      "You cannot lend funds to yourself"
    );

    require(now < loans[loanId].deadline, "Deadline has been reached");

    uint256 currentDebt = SafeMath.add(
      loans[loanId].amount,
      SafeMath.mul(
        loans[loanId].amount,
        uint256(loans[loanId].rate)
      ) / 10000
    );

    loans[loanId].currentDebt = currentDebt;

    loans[loanId].lender = hydroId;
    loans[loanId].status = Status.Ongoing;

    lendersToLoans[hydroId].push(loanId);

    users[hydroId].lent = SafeMath.add(
      users[hydroId].lent,
      loans[loanId].amount
    );

    users[loans[loanId].borrower].currentDebt = SafeMath.add(
      users[loans[loanId].borrower].currentDebt,
      currentDebt
    );

    emit LogLoanAccepted(loanId, loans[loanId].borrower, loans[loanId].lender);

    snowflake.transferSnowflakeBalanceFrom(loans[loanId].lender, loans[loanId].borrower, loans[loanId].amount);
  }

  function reimburse(uint256 loanId, uint256 amount) external {
    Snowflake snowflake = Snowflake(snowflakeAddress);

    IdentityRegistryInterface identity = IdentityRegistryInterface(identityRegistryAddress);
    uint256 hydroId = identity.getEIN(msg.sender);

    require(loans[loanId].status == Status.Ongoing, "Loan cannot be reimbursed at this moment");

    require(now < loans[loanId].deadline, "Deadline has been reached");

    require(
      loans[loanId].borrower == hydroId,
      "Sender is not the borrower of this loan"
    );

    require(amount <= loans[loanId].currentDebt, "Sent amount is too high");

    loans[loanId].currentDebt = SafeMath.sub(loans[loanId].currentDebt, amount);

    if (loans[loanId].currentDebt == 0) {
      loans[loanId].status = Status.Closed;

      emit LogLoanClosed(loanId);
    }

    users[loans[loanId].borrower].currentDebt = SafeMath.sub(
      users[loans[loanId].borrower].currentDebt,
      amount
    );

    users[loans[loanId].borrower].reimbursed = SafeMath.add(
      users[loans[loanId].borrower].reimbursed,
      amount
    );

    uint256 feesAmount = SafeMath.mul(amount, uint256(fees)) / 10000;

    uint256 reimbursedAmount = SafeMath.sub(amount, feesAmount);

    emit LogLoanReimbursed(loanId, amount);

    snowflake.transferSnowflakeBalanceFrom(loans[loanId].borrower, loans[loanId].lender, reimbursedAmount);

    snowflake.transferSnowflakeBalanceFrom(loans[loanId].borrower, snowflakeOwnerId, fees);
  }

  function getUserinfo(uint256 user) external view returns (
    uint256,
    uint256,
    uint256,
    uint256
  ) {
    return (
      users[user].currentDebt,
      users[user].lent,
      users[user].borrowed,
      users[user].reimbursed
    );
  }

  function getLoanInfo(uint256 loanId) external view returns (
    uint256,
    uint256,
    uint16,
    uint32,
    uint256,
    uint256
  ) {
    return (
      loans[loanId].amount,
      loans[loanId].currentDebt,
      loans[loanId].rate,
      loans[loanId].deadline,
      loans[loanId].borrower,
      loans[loanId].lender
    );
  }

  function getLoanStatus(uint256 loanId) external view returns (Status) {
    return loans[loanId].status;
  }

  function getEINFromAddress(address user) external view returns (uint256) {
    IdentityRegistryInterface identity = IdentityRegistryInterface(identityRegistryAddress);

    return identity.getEIN(user);
  }
}
