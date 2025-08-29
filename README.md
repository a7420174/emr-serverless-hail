# emr-serverless-hail

**Run Hail using Amazon EMR Serverless**

This repository contains a Dockerfile and scripts to run Hail on Amazon EMR Serverless.

The `Dockerfile` is based on the amazoncorretto:8 image (x86_64 architecture, Amazon Linux 2, Java 8 JDK). 
It installs Hail and its dependencies from Hail source code, and export 3rd-party Python libraries (`pyspark_hail.tar.gz`) and Hail JAR file (`hail-all-spark.jar`).
The default values of hail and spark version are `0.2.100` and `3.2.1`.

```bash
DOCKER_BUILDKIT=1 docker build --build-arg HAIL_VERSION=<value> --build-arg SPARK_VERSION=<value> --output ./out_files .
```

`hail-script-example.py` is a Python script that runs Hail on EMR Serverless. You can modify `hail_process` function of this script to run your own Hail script.

`emr-serverless.sh` bash script creates a **EMR serverless** cluster using [**AWS CLI**](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
You should have an AWS account and configure AWS CLI before running this script.
Also, you should have a S3 bucket to store the output of Hail script.

EMR serverless cluster is created with the following steps:

1. Create a job runtime role as described in [**AWS EMR documentation**](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/getting-started.html).
2. Create an EMR Serverless application using the AWS CLI.
```bash
aws emr-serverless create-application \
    --release-label emr-6.7.0 \
    --type "SPARK" \
    --name my-application
```
3. Submit a job run to your EMR Serverless application using `emr-serverless.sh` script. `entryPoint` represents the Python script that runs Hail on EMR Serverless, and `entryPointArguments` represents the arguments of this script. 
`sparkSubmitParameters` imports the Hail JAR file and 3rd-party Python libraries from the Docker image. `applicationConfiguration` in `configuration-overrides` option is for settings of Hail, and `monitoringConfiguration` set up a log directory in S3 bucket.

## Tips

```
Job failed, please check complete logs in configured logging destination. ExitCode: 1. Last few exceptions: Error summary: ConnectionPoolTimeoutException: Timeout waiting for connection from pool 
```
If an error above appears, I recommend a following solution.
Set more than `100` as a value of `spark.hadoop.fs.s3.maxConnections` property (default: `15`)
```
"classification": "spark-defaults",
"properties": {
    "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
    "spark.kryo.registrator": "is.hail.kryo.HailKryoRegistrator",
    "spark.hadoop.fs.s3.maxConnections": "1000",
}
```
