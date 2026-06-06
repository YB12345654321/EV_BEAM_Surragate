package beam.agentsim.agents.pricing

final case class ChargingDecisionContext(
  tick: Int,
  vehicleId: String,
  household: Boolean,
  parkingType: String,
  activityType: String,
  currentPrice: Double,
  referencePrice: Double,
  targetSocRatio: Double,
  socJ: Double,
  capacityJ: Double,
  socRatio: Double,
  targetJ: Double,
  deficitJ: Double,
  timeToDepartureSeconds: Int,
  durationSeconds: Int,
  chargerPowerKW: Double,
  estimatedDeparture: Int,
  userSegment: String,
  priceTolerance: Double,
  urgentTimeThresholdSeconds: Int,
  acceptedPriceThreshold: Double
)
