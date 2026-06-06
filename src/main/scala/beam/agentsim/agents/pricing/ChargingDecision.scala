package beam.agentsim.agents.pricing

final case class ChargingDecision(
  shouldCharge: Boolean,
  reason: String,
  powerMultiplier: Double,
  finalPowerKW: Double,
  chargeProbability: Double,
  socRatio: Double,
  deficitJ: Double,
  targetJ: Double,
  capacityJ: Double
)
