package beam.agentsim.agents.pricing

trait ChargingResponseModel {
  def decide(context: ChargingDecisionContext): ChargingDecision
}
