package beam.agentsim.agents.pricing

import java.io.{File, FileWriter, PrintWriter}

object SmartChargingCsvWriter {

  private val outputPath = "smart_charging_decisions.csv"
  private var initialized = false
  private var writer: PrintWriter = _

  private def escape(value: String): String = {
    if (value == null) ""
    else value.replace(",", "_").replace("\n", " ").replace("\r", " ")
  }

  private def initIfNeeded(): Unit = synchronized {
    if (!initialized) {
      val file = new File(outputPath)
      val append = file.exists()

      writer = new PrintWriter(new FileWriter(file, true))

      if (!append) {
        writer.println(
          Seq(
            "tick",
            "vehicle",
            "household",
            "parkingType",
            "activityType",
            "price",
            "decision",
            "userSegment",
            "priceTolerance",
            "targetSocRatio",
            "urgentTimeThresholdSeconds",
            "acceptedPriceThreshold",
            "duration",
            "rawPowerKW",
            "finalPowerKW",
            "socJ",
            "socRatio",
            "deficitJ",
            "targetJ",
            "capacityJ",
            "estimatedDeparture"
          ).mkString(",")
        )
        writer.flush()
      }

      initialized = true
    }
  }

  def write(
    tick: Int,
    vehicle: String,
    household: Boolean,
    parkingType: String,
    activityType: String,
    price: Double,
    decision: String,
    userSegment: String,
    priceTolerance: Double,
    targetSocRatio: Double,
    urgentTimeThresholdSeconds: Int,
    acceptedPriceThreshold: Double,
    duration: Int,
    rawPowerKW: Double,
    finalPowerKW: Double,
    socJ: Double,
    socRatio: Double,
    deficitJ: Double,
    targetJ: Double,
    capacityJ: Double,
    estimatedDeparture: Int
  ): Unit = synchronized {
    initIfNeeded()

    writer.println(
      Seq(
        tick.toString,
        escape(vehicle),
        household.toString,
        escape(parkingType),
        escape(activityType),
        price.toString,
        escape(decision),
        escape(userSegment),
        priceTolerance.toString,
        targetSocRatio.toString,
        urgentTimeThresholdSeconds.toString,
        acceptedPriceThreshold.toString,
        duration.toString,
        rawPowerKW.toString,
        finalPowerKW.toString,
        socJ.toString,
        socRatio.toString,
        deficitJ.toString,
        targetJ.toString,
        capacityJ.toString,
        estimatedDeparture.toString
      ).mkString(",")
    )

    writer.flush()
  }
}
