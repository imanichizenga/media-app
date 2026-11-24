"""Typed access to the small set of bootstrap environment variables (ADR-0011)."""

import os


class MissingEnv(RuntimeError):
    pass


def env_str(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None or (value == "" and default is None):
        raise MissingEnv(f"Required environment variable {name} is not set")
    return value


def env_bool(name: str, default: bool = False) -> bool:
    raw = os.environ.get(name)
    return default if raw is None else raw.strip().lower() in {"1", "true", "yes", "on"}


def env_int(name: str, default: int) -> int:
    return int(os.environ.get(name, default))


def env_list(name: str, default: str = "") -> list[str]:
    return [part.strip() for part in os.environ.get(name, default).split(",") if part.strip()]
