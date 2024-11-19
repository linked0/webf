interface InterestRateModelInterface {
    // slope
    function multiplierPerBlock() external view returns (uint256);
}