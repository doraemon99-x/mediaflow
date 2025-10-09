FROM python:3.13.5-slim

# --- Environment ---
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8888
ENV POETRY_VERSION=1.8.3
# Jika pakai SOCKS5 proxy, uncomment dan sesuaikan
# ENV all_proxy="socks5://127.0.0.1:1080"

WORKDIR /mediaflow_proxy

# --- Install dependencies & Poetry ---
USER root
RUN apt-get update && apt-get install -y curl build-essential \
    && pip install --no-cache-dir "poetry==$POETRY_VERSION" \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Poetry biasanya terinstall di /usr/local/bin
ENV PATH="/usr/local/bin:$PATH"

# --- Add non-root user ---
RUN useradd -m mediaflow_proxy \
    && chown -R mediaflow_proxy:mediaflow_proxy /mediaflow_proxy

USER mediaflow_proxy

# --- Copy requirement files & install Python deps ---
COPY --chown=mediaflow_proxy:mediaflow_proxy pyproject.toml poetry.lock* /mediaflow_proxy/

RUN poetry config virtualenvs.in-project true \
    && poetry install --no-interaction --no-ansi --no-root --only main

# --- Copy project files ---
COPY --chown=mediaflow_proxy:mediaflow_proxy . /mediaflow_proxy

EXPOSE 8888

# --- Run Gunicorn via Poetry ---
CMD ["sh", "-c", "exec poetry run gunicorn mediaflow_proxy.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8888 --timeout 120 --max-requests 500 --max-requests-jitter 200 --access-logfile - --error-logfile - --log-level info --forwarded-allow-ips \"${FORWARDED_ALLOW_IPS:-127.0.0.1}\""]
