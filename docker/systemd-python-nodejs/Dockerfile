# Fedora-based Dockerfile for (Python 3.10 + Node.js 18)
FROM fedora:39

# Install system dependencies
RUN dnf update -y && dnf install -y \
    curl wget gcc gcc-c++ make git supervisor \
    python3.10 python3.10-devel python3-pip postgresql-devel \
    && dnf clean all

# Install Node.js 18
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - && dnf install -y nodejs

# Create app user
RUN useradd -m -u 1000 appuser
WORKDIR /app
RUN chown appuser:appuser /app

# Setup Python virtual environment
USER appuser
RUN python3.10 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install Python dependencies
COPY --chown=appuser:appuser backend/requirements.txt /app/backend/
RUN pip install --upgrade pip && pip install -r /app/backend/requirements.txt

# Install Node.js dependencies
COPY --chown=appuser:appuser ui/package*.json /app/ui/
WORKDIR /app/ui
RUN npm ci --only=production

# Copy application code
WORKDIR /app
COPY --chown=appuser:appuser backend/ /app/backend/
COPY --chown=appuser:appuser ui/ /app/ui/
COPY --chown=appuser:appuser export-data-validation/ /app/export-data-validation/

# Build React frontend
WORKDIR /app/ui
RUN npm run build

# Create configuration files and startup script
USER root
WORKDIR /app

# Copy configuration files
COPY docker-configs/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-configs/start.sh /app/start.sh
COPY docker-configs/healthcheck.sh /app/healthcheck.sh

# Make scripts executable and create directories
RUN chmod +x /app/start.sh /app/healthcheck.sh && \
    mkdir -p /var/log/supervisor

# Set environment
ENV PYTHONPATH=/app/backend
ENV NODE_ENV=production
ENV REACT_APP_API_BASE_URL=http://localhost:8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /app/healthcheck.sh

EXPOSE 3000 8000
VOLUME ["/app/venv"]
USER appuser

CMD ["/app/start.sh"]