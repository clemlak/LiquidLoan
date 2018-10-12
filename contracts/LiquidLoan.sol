pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
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

  /* TODO: Do we keep this? */
  uint256 public signUpFee = 1000000000000000000;

  /* hydroId are linked to a score */
  mapping (string => uint256) internal usersToScores;

  uint256 public startingScore = 10000;

  /**
   * Our loans can have 3 different states:
   * - Pending: the request of a loan has been published but not accepted yet
   * - Accepted: the request has been accepted, the loan is on-going
   * - Closed: the loan has been totally reimbursed
   */
  enum Status { Pending, Accepted, Closed }

  /**
   * This defines how are loans are structured:
   * - amount: the amount of Hydro
   * - status: the current status of the loan
   * - rate: the rate of a loan (can only be fixed)
   * - timeframe: the timeframe in months
   */
  struct Loan {
    uint256 amount;
    Status status;
    uint16 rate;
    uint8 timeframe;
  }

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

    if (usersToScores[hydroId] == 0) {
      usersToScores[hydroId] = startingScore;
    }

    return true;
  }


}
