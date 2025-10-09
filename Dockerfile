FROM python:3.13.5-slim

# --- Environment umum ---
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8080
ENV POETRY_VERSION=1.8.3

# --- Proxy saat build ---
ENV http_proxy="http://dknebqij:phd93xglfe0y@45.38.111.112:6027"
ENV https_proxy="http://dknebqij:phd93xglfe0y@45.38.111.112:6027"
ENV all_proxy="http://dknebqij:phd93xglfe0y@45.38.111.112:6027"

# --- Install dependencies ---
USER root
RUN apt-get update && apt-get install -y curl build-essential \
    && pip install --no-cache-dir "poetry==$POETRY_VERSION" \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Add non-root user ---
RUN useradd -m mediaflow_proxy
WORKDIR /mediaflow_proxy
RUN chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy

USER mediaflow_proxy
ENV PATH="/home/mediaflow_proxy/.local/bin:$PATH"

# --- Copy dan install dependency Python ---
COPY --chown=mediaflow_proxy:mediaflow_proxy pyproject.toml poetry.lock* /mediaflow_proxy/
RUN poetry config virtualenvs.in-project true \
    && poetry install --no-interaction --no-ansi --no-root --only main

# --- Copy seluruh file project ---
COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy

# --- Runtime proxy config (opsional, bisa juga set dari luar) ---
# ENV PROXY_URL="http://dknebqij:phd93xglfe0y@45.38.111.112:6027"
# ENV ALL_PROXY=true

EXPOSE 8080

# --- Jalankan app ---
CMD ["sh", "-c", "exec poetry run gunicorn mediaflow_proxy.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8080 --timeout 120 --max-requests 500 --max-requests-jitter 200 --access-logfile - --error-logfile - --log-level info --forwarded-allow-ips \"${FORWARDED_ALLOW_IPS:-127.0.0.1}\""]
