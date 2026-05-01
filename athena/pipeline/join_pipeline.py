from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("JoinPipeline").getOrCreate()

# Read tables (update paths and formats as needed)
table1 = spark.read.parquet("s3://your-bucket/table1/")
table2 = spark.read.parquet("s3://your-bucket/table2/")

# Join tables (update join key as needed)
result = table1.join(table2, on="id", how="inner")

# Write to S3
result.write.mode("overwrite").parquet("s3://s33ding-kafka-output/db_silver/")

spark.stop()
