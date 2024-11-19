import "@openzeppelin/contracts/math/SafeMath.sol";

contract JumpRateModelV2 {
  using SafeMath for uint;
  uint public multiplierPerBlock;
  
  constructor(uint multiplierPerYear) public {
    multiplierPerBlock = multiplierPerYear.div(2628000);
  }
}