# Multi-stage build for smaller final image
# Build stage
FROM fedora:42 as builder

# Set environment variables for build
ENV JAVA_HOME=/opt/apps/openjdk21
ENV PYTHON_HOME=/opt/apps/python311
ENV VENV_HOME=/opt/apps/venv3
ENV PATH=$JAVA_HOME/bin:$PYTHON_HOME/bin:$VENV_HOME/bin:$PATH

# Install build dependencies
RUN microdnf install -y \
    wget \
    tar \
    gzip \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    libffi-devel \
    zlib-devel \
    readline-devel \
    sqlite-devel \
    bzip2-devel \
    xz-devel \
    ncurses-devel \
    tk-devel \
    gdbm-devel \
    libpcap-devel \
    expat-devel \
    gettext \
    awk \
    && microdnf clean all

# Create application directories
RUN mkdir -p /opt/apps/openjdk21 /opt/apps/python311 /opt/apps/venv3

# Download and install Amazon Corretto JDK 21
RUN cd /tmp && \
    wget -O corretto-jdk.tar.gz https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz && \
    tar -xzf corretto-jdk.tar.gz && \
    mv amazon-corretto-21.* /opt/apps/openjdk21-temp && \
    mv /opt/apps/openjdk21-temp/* /opt/apps/openjdk21/ && \
    rmdir /opt/apps/openjdk21-temp && \
    rm -f corretto-jdk.tar.gz && \
    chmod -R 755 /opt/apps/openjdk21

# Download and compile Python 3.11 from source
RUN cd /tmp && \
    wget https://www.python.org/ftp/python/3.11.11/Python-3.11.11.tar.xz && \
    tar -xf Python-3.11.11.tar.xz && \
    cd Python-3.11.11 && \
    ./configure --prefix=/opt/apps/python311 --enable-optimizations --with-ssl && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/Python-3.11.11* && \
    chmod -R 755 /opt/apps/python311

# Create virtual environment and install AWS CLI
RUN /opt/apps/python311/bin/python3.11 -m venv /opt/apps/venv3 && \
    /opt/apps/venv3/bin/pip install --upgrade pip && \
    /opt/apps/venv3/bin/pip install awscli && \
    chmod -R 755 /opt/apps/venv3

# Runtime stage
FROM fedora:42

# Set environment variables
ENV JAVA_HOME=/opt/apps/openjdk21
ENV PYTHON_HOME=/opt/apps/python311
ENV VENV_HOME=/opt/apps/venv3
ENV PATH=$JAVA_HOME/bin:$PYTHON_HOME/bin:$VENV_HOME/bin:$PATH
ENV AWS_REGION=us-east-1

# Install minimal runtime dependencies
RUN microdnf install -y \
    tar \
    gzip \
    awk \
    grep \
    sed \
    vi \
    gawk \
    gettext \
    nss_wrapper \
    openssl \
    shadow-utils \
    && microdnf clean all

# Copy built applications from builder stage
COPY --from=builder /opt/apps/openjdk21 /opt/apps/openjdk21
COPY --from=builder /opt/apps/python311 /opt/apps/python311
COPY --from=builder /opt/apps/venv3 /opt/apps/venv3

# Create directories
RUN mkdir -p /workspace /home/appadmin

# Create passwd template for OpenShift user ID support
RUN echo 'appadmin:x:${USER_ID}:${GROUP_ID}:App Admin:/home/appadmin:/bin/bash' > /home/appadmin/passwd.template

# Copy scripts
COPY entrypoint.sh /entrypoint.sh
COPY run.sh /run.sh

# Make scripts executable  
RUN chmod +x /entrypoint.sh /run.sh

# Set working directory
WORKDIR /workspace

# Create non-root user for OpenShift compatibility
RUN groupadd -g 1001 appadmin && \
    useradd -u 1001 -g appadmin -d /home/appadmin -s /bin/bash appadmin && \
    chown -R appadmin:appadmin /opt/apps /workspace /home/appadmin && \
    chmod -R g+rw /opt/apps /workspace /home/appadmin && \
    chmod g+x /opt/apps/openjdk21/bin/* /opt/apps/python311/bin/* /opt/apps/venv3/bin/*

# Switch to non-root user
USER 1001

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/run.sh"]