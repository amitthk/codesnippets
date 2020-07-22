import scala.io.Source
import org.apache.spark.{SparkContext, SparkConf}

object orderListFromS3{
  def main(args: Array[String]) = {
    val accessKeyId = args(0).toString//System.getenv("AWS_ACCESS_KEY_ID")
    val secretAccessKey = args(1).toString//System.getenv("AWS_SECRET_ACCESS_KEY")
    val conf = new SparkConf().setMaster("local").setAppName("spark-play")
    val sc = new SparkContext(conf)
    val orderId = args(2).toInt
    sc.hadoopConfiguration.set("fs.s3n.awsAccessKeyId", accessKeyId)
    sc.hadoopConfiguration.set("fs.s3n.awsSecretAccessKey", secretAccessKey)
    sc.hadoopConfiguration.set("fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    val orderItems = sc.textFile("s3a://atksv.mywire.org/data/retail_db/order_items/part-00000")
    val orderRevenue = orderItems.filter(orderitem => orderitem.split(",")(1).toInt == orderId).
      map(orderitem => orderitem.split(",")(4).toFloat).
      reduce((t, v) => t + v)
    println(orderRevenue)
  }
}