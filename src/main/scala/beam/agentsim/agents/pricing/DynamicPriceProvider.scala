package beam.agentsim.agents.pricing

import scala.io.Source

object DynamicPriceProvider {

  private var priceByTime: Vector[(Int, Double)] = Vector.empty
  private var defaultPrice: Double = 0.25
  private var loaded: Boolean = false

  def loadCsv(path: String, defaultPriceValue: Double = 0.25): Unit = {
    defaultPrice = defaultPriceValue

    val source = Source.fromFile(path)
    try {
      val rows = source.getLines().drop(1).flatMap { line =>
        val parts = line.split(",").map(_.trim)
        if (parts.length >= 2 && parts(0).nonEmpty && parts(1).nonEmpty) {
          Some(parts(0).toInt -> parts(1).toDouble)
        } else {
          None
        }
      }.toVector.sortBy(_._1)

      priceByTime = rows
      loaded = true
    } finally {
      source.close()
    }
  }

  def getPrice(tick: Int): Double = {
    if (!loaded || priceByTime.isEmpty) {
      defaultPrice
    } else {
      val idx = priceByTime.lastIndexWhere { case (time, _) => time <= tick }
      if (idx >= 0) priceByTime(idx)._2 else defaultPrice
    }
  }
}
