#!/usr/bin/env python
# coding: utf-8

# In[11]:


from dotenv import load_dotenv;
load_dotenv()
import os
import boto3
import findspark
findspark.init() 
from pyspark.sql.types import StructType, StructField, StringType, DoubleType
from pyspark.sql import SparkSession
import pyspark
from pyspark import SQLContext
# Setup the Configuration
conf = pyspark.SparkConf()
spark_context = SparkSession.builder.config(conf=conf).getOrCreate()


# In[12]:


key = os.environ["AWS_ACCESS_KEY"]
secret = os.environ["AWS_SECRET_ACCESS_KEY"]


# In[18]:


s3 = boto3.client('s3')
objects=s3.list_objects(Bucket="atksv.mywire.org")

schema = StructType([
    StructField("Key", StringType()),
    StructField("Size", DoubleType())
])
filtered=list(map(lambda itm:[itm['Key'],float(str(itm['Size']))],objects['Contents']))
df = spark_context.createDataFrame(filtered, schema)


# In[20]:


df.count()


# In[21]:


df.explain()


# In[ ]:




