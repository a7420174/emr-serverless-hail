# Dockerfile
FROM amazoncorretto:8 AS hail_build
ARG HAIL_VERSION=0.2.100
ARG SPARK_VERSION=3.2.1

RUN yum -y update
RUN yum -y install yum-utils git gcc-c++ openblas-devel lapack-devel lz4-devel python3 python3-pip rsync
RUN yum -y groupinstall development

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip install venv-pack==0.2.0
RUN git clone https://github.com/hail-is/hail.git /hail
WORKDIR /hail/hail
RUN git checkout tags/${HAIL_VERSION}
RUN make install-on-cluster HAIL_COMPILE_NATIVES=1 SCALA_VERSION=2.12.13 SPARK_VERSION=${SPARK_VERSION}

RUN mkdir /output && venv-pack -o /output/pyspark_hail.tar.gz

FROM scratch AS export
COPY --from=hail_build /output/pyspark_hail.tar.gz /
COPY --from=hail_build /opt/venv/lib/python3.*/site-packages/hail/backend/hail-all-spark.jar /
