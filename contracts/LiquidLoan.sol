/* solhint-disable not-rely-on-time, function-max-lines */

pragma solidity 0.5.0;

import "./SafeMath.sol";
import "./SnowflakeResolver.sol";
import "./IdentityRegistryInterface.sol";
import "./SnowflakeInterface.sol";


/**
 * @title Base contract for LiquidLoan
 * @dev P2P crypto lending dApp built into the Snowflake dApp store (Proof of concept)
 * @author Clemlak https://github.com/clemlak
 */
contract LiquidLoan is SnowflakeResolver {
  constructor(address snowflakeAddress) public SnowflakeResolver(
    "LiquidLoan",
    "P2P crypto lending",
    snowflakeAddress,
    false,
    false
  ) {
  }

  function onAddition(uint ein, uint, bytes memory) public senderIsSnowflake() returns (bool) {}
  function onRemoval(uint, bytes memory) public senderIsSnowflake() returns (bool) {}

  uint16 public fees = 150;
  uint256 public ownerEin = 25;

  struct User {
    uint256 currentDebt;
    uint256 lent;
    uint256 borrowed;
    uint256 reimbursed;
  }

  mapping (uint256 => User) private users;

  enum Status { Open, Ongoing, Closed }

  struct Loan {
    uint256 amount;
    uint256 currentDebt;
    uint256 borrower;
    uint256 lender;
    Status status;
    uint16 rate;
    uint32 deadline;
    uint32 createdAt;
  }

  Loan[] public loans;

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

  function setOwnerEin(uint256 newOwnerEin) external onlyOwner() {
    ownerEin = newOwnerEin;
  }

  function requestLoan(uint256 amount, uint16 rate, uint32 deadline) external {
    SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

    uint256 ein = identityRegistry.getEIN(msg.sender);
    require(identityRegistry.isResolverFor(ein, address(this)), "The EIN has not sent this resolver");

    uint256 currentDebt = SafeMath.add(
      amount,
        SafeMath.mul(
          amount,
          rate
        ) / 100
    );

    uint256 loanId = loans.push(
      Loan({
        amount: amount,
        currentDebt: currentDebt,
        rate: rate,
        deadline: deadline,
        status: Status.Open,
        borrower: ein,
        lender: 0,
        createdAt: uint32(now)
      })
    ) - 1;

    borrowersToLoans[ein].push(loanId);

    emit LogLoanRequested(loanId, loans[loanId].borrower);
  }

  function lend(uint256 loanId) external {
    SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

    uint256 ein = identityRegistry.getEIN(msg.sender);
    require(identityRegistry.isResolverFor(ein, address(this)), "The EIN has not sent this resolver");

    require(loans[loanId].status == Status.Open, "Loan is not open");

    require(
      loans[loanId].borrower != ein,
      "You cannot lend funds to yourself"
    );

    require(now < loans[loanId].deadline, "Deadline has been reached");

    loans[loanId].lender = ein;
    loans[loanId].status = Status.Ongoing;

    lendersToLoans[ein].push(loanId);

    users[ein].lent = SafeMath.add(
      users[ein].lent,
      loans[loanId].amount
    );

    users[loans[loanId].borrower].currentDebt = SafeMath.add(
      users[loans[loanId].borrower].currentDebt,
      loans[loanId].currentDebt
    );

    emit LogLoanAccepted(loanId, loans[loanId].borrower, loans[loanId].lender);

    snowflake.transferSnowflakeBalanceFrom(loans[loanId].lender, loans[loanId].borrower, loans[loanId].amount);
  }

  function reimburse(uint256 loanId, uint256 amount) external {
    SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
    IdentityRegistryInterface identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());

    uint256 ein = identityRegistry.getEIN(msg.sender);
    require(identityRegistry.isResolverFor(ein, address(this)), "The EIN has not sent this resolver");


    require(loans[loanId].status == Status.Ongoing, "Loan cannot be reimbursed at this moment");

    require(now < loans[loanId].deadline, "Deadline has been reached");

    require(
      loans[loanId].borrower == ein,
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

    snowflake.transferSnowflakeBalanceFrom(loans[loanId].borrower, ownerEin, fees);
  }

  function withdrawFees(address to) public onlyOwner() {
    SnowflakeInterface snowflake = SnowflakeInterface(snowflakeAddress);
    HydroInterface hydro = HydroInterface(snowflake.hydroTokenAddress());
    withdrawHydroBalanceTo(to, hydro.balanceOf(address(this)));
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

  function getUserLentLoans(uint256 user) external view returns (uint256[] memory) {
    return lendersToLoans[user];
  }

  function getUserBorrowedLoans(uint256 user) external view returns (uint256[] memory) {
    return borrowersToLoans[user];
  }

  function getLoanInfo(uint256 loanId) external view returns (
    uint256,
    uint256,
    uint16,
    uint32,
    uint256,
    uint256,
    uint32
  ) {
    return (
      loans[loanId].amount,
      loans[loanId].currentDebt,
      loans[loanId].rate,
      loans[loanId].deadline,
      loans[loanId].borrower,
      loans[loanId].lender,
      loans[loanId].createdAt
    );
  }

  function getLoanStatus(uint256 loanId) external view returns (Status) {
    return loans[loanId].status;
  }

  function getLoansCount() external view returns (uint256) {
    return loans.length;
  }
}
