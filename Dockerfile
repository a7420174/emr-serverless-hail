# Dockerfile
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS hail_build
ARG HAIL_VERSION=0.2.135
ARG SPARK_VERSION=3.5.0

# Update and install required packages (using dnf instead of yum)
RUN dnf update -y && \
    dnf install -y dnf-utils git gcc-c++ openblas-devel lapack-devel lz4-devel python3.11 python3.11-pip rsync java-11-amazon-corretto-devel glibc-langpack-en && \
    dnf groupinstall -y "Development Tools"

# Create virtual environment with Python 3.11
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Set JAVA_HOME to point to the JDK (required for JNI headers like jni.h)
ENV JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
# Set UTF-8 locale to handle special characters in file paths (fixes InvalidPathException)
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Upgrade pip to handle recent package versions
RUN pip install --upgrade pip

# Install required Python packages
RUN pip install venv-pack==0.2.0 build uv
RUN git clone https://github.com/hail-is/hail.git /hail
WORKDIR /hail/hail
RUN git checkout tags/${HAIL_VERSION}
# Build Hail
RUN make install-on-cluster HAIL_RELEASE_MODE=1 HAIL_COMPILE_NATIVES=1 SCALA_VERSION=2.12.18 SPARK_VERSION=${SPARK_VERSION}

# Package the environment
RUN mkdir /output && venv-pack -o /output/pyspark_hail.tar.gz

# Export stage
FROM scratch AS export
COPY --from=hail_build /output/pyspark_hail.tar.gz /
COPY --from=hail_build /opt/venv/lib/python3.*/site-packages/hail/backend/hail-all-spark.jar /
