import scala.io.Source

object OrderRevenue{
    val orderItems = Source.fromFile("/Users/amitthk/projects/data-master/retail_db/order_items/part-00000").getLines
    val orderRevenue = orderItems.filter( orderitem => orderitem.split(",")(1).toInt == 2).
    map(orderitem => orderitem.split(",")(4).toFloat).
    reduce((t,v) => t+v)
    println(OrderRevenue)
}
