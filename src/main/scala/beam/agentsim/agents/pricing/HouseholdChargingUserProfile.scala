package beam.agentsim.agents.pricing

object HouseholdChargingUserProfile {

  final case class Profile(
    segment: String,
    priceTolerance: Double,
    targetSocRatio: Double,
    urgentTimeThresholdSeconds: Int
  )

  private val priceSensitive = Profile(
    segment = "price_sensitive",
    priceTolerance = -0.10,
    targetSocRatio = 0.80,
    urgentTimeThresholdSeconds = 7200
  )

  private val balanced = Profile(
    segment = "balanced",
    priceTolerance = 0.00,
    targetSocRatio = 0.80,
    urgentTimeThresholdSeconds = 3600
  )

  private val convenienceOriented = Profile(
    segment = "convenience_oriented",
    priceTolerance = 0.20,
    targetSocRatio = 0.85,
    urgentTimeThresholdSeconds = 1800
  )

  def profileForVehicle(vehicleId: String): Profile = {
    val bucket = math.abs(vehicleId.hashCode) % 3

    bucket match {
      case 0 => priceSensitive
      case 1 => balanced
      case _ => convenienceOriented
    }
  }
}
