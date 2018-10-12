pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ERC20.sol";
import "./SnowflakeResolver.sol";
import "./Snowflake.sol";


/**
 * @title Base contract for LiquidLoan
 * @dev Proof-of-Concept crypto lending dApp built into the Snowflake dApp store
 * @author Clemlak https://github.com/clemlak
 */
contract LiquidLoan is SnowflakeResolver {
  constructor() public {
    snowflakeName = "LiquidLoan";
    snowflakeDescription = "Crypto loan";
    snowflakeAddress = 0x920b3eD908F5E63DC859C0D61cA2a270f0663e58;

    callOnSignUp = true;
    callOnRemoval = true;
  }

  address public hydroTokenContractAddress = 0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20;
  uint256 public tokenFactor = 10 ** 18;

  /* TODO: Do we keep this? */
  uint256 public signUpFee = 1000000000000000000;

  uint16 public liquidFees;

  /* hydroId are linked to a score */
  mapping (string => uint256) internal usersToScores;

  uint256 public startingScore = 500;

  /**
   * Our loans can have 3 different states:
   * - Pending: the request of a loan has been published but not accepted yet
   * - Accepted: the request has been accepted, the loan is on-going
   * - Closed: the loan has been totally reimbursed
   */
  enum Status { Open, Accepted, Closed }

  /**
   * This defines how are loans are structured:
   * - amount: the amount of Hydro
   * - status: the current status of the loan
   * - rate: the (fixed) rate of a loan, from 1 (0.01 %) to 10000 (100%)
   * - deadline: the deadline to reimburse the loan (timestamp)
   */
  struct Loan {
    uint256 amount;
    uint256 currentDebt;
    Status status;
    uint16 rate;
    uint32 deadline;
  }

  Loan[] public loans;

  mapping (string => uint256[]) public lendersToLoans;
  mapping (string => uint256[]) public borrowersToLoans;
  mapping (uint256 => string) public loansToLenders;
  mapping (uint256 => string) public loansToBorrowers;

  event LogLoanRequest(
    uint256 loanId,
    string borrower
  );

  event LogLoanAccepted(
    uint256 loanId,
    string borrower,
    string lender
  );

  event LogLoanClosed(
    uint256 loanId
  );

  /**
   * @dev Requests a new loan
   */
  function requestLoan(
    uint256 amount,
    uint16 rate,
    uint8 deadline
  ) external {
    Snowflake snowflake = Snowflake(snowflakeAddress);
    string memory hydroId = snowflake.getHydroId(msg.sender);

    uint256 loanId = loans.push(
      Loan({
        amount: amount,
        currentDebt: SafeMath.mul(amount, rate) / 100,
        rate: rate,
        deadline: deadline,
        status: Status.Open
      })
    ) - 1;

    borrowersToLoans[hydroId].push(loanId);
    loansToBorrowers[loanId] = hydroId;
  }

  function lend(uint256 loanId) external {
    require(loans[loanId].status == Status.Open, "Loan is not open anymore");

    Snowflake snowflake = Snowflake(snowflakeAddress);
    string memory hydroId = snowflake.getHydroId(msg.sender);

    ERC20 hydroToken = ERC20(hydroTokenContractAddress);

    require(
      hydroToken.allowance(hydroId, address(this)) >= loans[loanId].amount,
      "Contract is not allowed to handle lender funds"
    );

    loansToLenders[loanId] = hydroId;
    lendersToLoans[hydroId].push(loanId);

    loans[loanId].status = Status.Accepted;

    usersToScores[hydroId] = SafeMath.add(
      usersToScores[hydroId],
      loans[loanId].amount / tokenFactor
    );

    hydroToken.transferFrom(loansToLenders[loanId], loansToBorrowers[loanId], loans[loanId].amount);
  }

  function reimburse(uint256 loanId, uint256 amount) external {
    require(loans[loandId].status == Status.Accepted, "Loan can not be reimbursed yet");

    /* solhint-disable not-rely-on-time */
    require(now < loans[loandId].deadline, "Deadline has already been reached");

    Snowflake snowflake = Snowflake(snowflakeAddress);
    string memory hydroId = snowflake.getHydroId(msg.sender);

    /* Do we need to compare string hashes? */
    require(loansToBorrowers[loanId] == hydroId, "Sender is not the borrower of this loan");

    require(amount <= loans[loandId].currentDebt, "Sent amount is higher than the funds to go");

    ERC20 hydroToken = ERC20(hydroTokenContractAddress);

    require(
      hydroToken.allowance(hydroId, address(this)) >= loans[loandId].currentDebt,
      "Contract is not allowed to handle borrower funds"
    );

    loans[loanId].currentDebt = SafeMath.sub(loans[loanId].currentDebt, amount);

    if (loans[loanId].currentDebt == 0) {
      loans[loandId].status = Status.Closed;
    }

    uint256 fees = SafeMath.mul(amount, liquidFees) / 100;

    usersToScores[loansToBorrowers[loanId]] = SafeMath.add(
      usersToScores[loansToBorrowers[loanId]],
      amount / tokenFactor
    );

    hydroToken.transferFrom(loansToBorrowers[loanId], loansToLenders[loanId], SafeMath.sub(amount, fees));
    hydroToken.transferFrom(loansToBorrowers[loanId], owner, fees);
  }

  function confront(uint256 loanId) external {
    require(loans[loanId].status == Status.Accepted, "Loan does not have the right status");

    require(loans[loanId].currentDebt > 0, "Loan debt has been reimbursed");

    /* solhint-disable not-rely-on-time */
    require(now > loans[loandId].deadline, "Deadline has not been reached yet");

    usersToScores[loansToBorrowers[loanId]] = SafeMath.sub(
      usersToScores[loansToBorrowers[loanId]],
      loans[loanId].currentDebt / tokenFactor
    );
  }

  /**
   * @dev Signs up an user to our dApp
   */
  function onSignUp(string hydroId, uint allowance) public returns (bool) {
    require(msg.sender == snowflakeAddress, "Snowflake must be the sender");

    /* TODO: Do we need a sign up fee? */
    /*
    require(allowance == signUpFee, "Sign up fee is too low");
    Snowflake snowflake = Snowflake(snowflakeAddress);
    require(snowflake.withdrawFrom(hydroId, owner, signUpFee), "Could not charge fee");
    */

    /**
     * TODO: Prevent users with a score lower than the startingScore
     * to sign out and sign up again to get a higher score
     */
    if (usersToScores[hydroId] == 0) {
      usersToScores[hydroId] = startingScore;
    }

    return true;
  }
}
