name := "testproject"
version:= "1.0.0"
scalaVersion := "2.10.6"
val sparkVersion = "1.6.3"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % sparkVersion,
  "org.apache.spark" %% "spark-sql" % sparkVersion
)


libraryDependencies ++= Seq(
  "com.amazonaws" % "aws-java-sdk" % "1.11.46",
  "org.apache.hadoop" % "hadoop-aws" % "2.10.0"
)
