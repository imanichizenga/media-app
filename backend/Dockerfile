# syntax=docker/dockerfile:1
FROM python:3.14-slim-trixie AS build
COPY --from=ghcr.io/astral-sh/uv:0.13.9 /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PROJECT_ENVIRONMENT=/opt/venv UV_PYTHON_DOWNLOADS=never
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

FROM python:3.14-slim-trixie
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
  # The runtime installs nothing: pip and its vendored libraries are only attack surface.
  && rm -rf /usr/local/lib/python3.14/site-packages/pip* /usr/local/lib/python3.14/ensurepip /usr/local/bin/pip* \
  && groupadd -g 10001 app && useradd -u 10001 -g app -M -s /usr/sbin/nologin app
COPY --from=build /opt/venv /opt/venv
WORKDIR /app
COPY manage.py ./
COPY config config
COPY newsplatform newsplatform
ENV PATH=/opt/venv/bin:$PATH PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 DJANGO_SETTINGS_MODULE=config.settings.production WEB_CONCURRENCY=2
USER 10001
EXPOSE 8000
CMD ["gunicorn", "config.asgi:application", "-k", "uvicorn_worker.UvicornWorker", "-b", "0.0.0.0:8000", "--worker-tmp-dir", "/tmp", "--graceful-timeout", "30"]
