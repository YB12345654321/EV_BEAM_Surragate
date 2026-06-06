package beam.agentsim.agents.pricing

object HouseholdSmartChargingManager extends ChargingResponseModel {

  val TargetSocFraction: Double = 0.80
  val ReferencePrice: Double = 0.25
  val PriceTolerance: Double = 0.00
  val UrgentTimeThresholdSeconds: Int = 3600

  override def decide(context: ChargingDecisionContext): ChargingDecision = {
    val remainingAfterThisStep =
      math.max(0, context.timeToDepartureSeconds - context.durationSeconds)

    val maxFutureEnergyJ =
      context.chargerPowerKW * 1000.0 * remainingAfterThisStep

    val urgentByEnergy =
      context.deficitJ > maxFutureEnergyJ

    val urgentByTime =
      context.timeToDepartureSeconds <= context.urgentTimeThresholdSeconds

    val urgent =
      urgentByEnergy || urgentByTime

    val priceAcceptable =
      context.currentPrice <= context.acceptedPriceThreshold

    if (context.deficitJ <= 0.0) {
      ChargingDecision(
        shouldCharge = false,
        reason = "target_soc_reached",
        powerMultiplier = 0.0,
        finalPowerKW = 0.0,
        chargeProbability = 0.0,
        socRatio = context.socRatio,
        deficitJ = context.deficitJ,
        targetJ = context.targetJ,
        capacityJ = context.capacityJ
      )
    } else if (urgent) {
      ChargingDecision(
        shouldCharge = true,
        reason = "urgent",
        powerMultiplier = 1.0,
        finalPowerKW = context.chargerPowerKW,
        chargeProbability = 1.0,
        socRatio = context.socRatio,
        deficitJ = context.deficitJ,
        targetJ = context.targetJ,
        capacityJ = context.capacityJ
      )
    } else if (priceAcceptable) {
      ChargingDecision(
        shouldCharge = true,
        reason = "price_acceptable",
        powerMultiplier = 1.0,
        finalPowerKW = context.chargerPowerKW,
        chargeProbability = 1.0,
        socRatio = context.socRatio,
        deficitJ = context.deficitJ,
        targetJ = context.targetJ,
        capacityJ = context.capacityJ
      )
    } else {
      ChargingDecision(
        shouldCharge = false,
        reason = "wait_price_high",
        powerMultiplier = 0.0,
        finalPowerKW = 0.0,
        chargeProbability = 0.0,
        socRatio = context.socRatio,
        deficitJ = context.deficitJ,
        targetJ = context.targetJ,
        capacityJ = context.capacityJ
      )
    }
  }
}
