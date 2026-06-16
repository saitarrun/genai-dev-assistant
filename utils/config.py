"""Configuration management utilities."""

import json
import os
from pathlib import Path
from typing import Dict, Any, Optional


def get_config_path() -> Path:
    """Get the standard config file path."""
    return Path.home() / ".genai-assistant" / "config.json"


def ensure_config_directory() -> Path:
    """Create config directory if it doesn't exist."""
    config_dir = Path.home() / ".genai-assistant"
    config_dir.mkdir(parents=True, exist_ok=True)
    return config_dir


def load_config() -> Dict[str, Any]:
    """Load configuration from file.

    Returns:
        Config dict, or empty dict if file doesn't exist
    """
    config_path = get_config_path()

    if not config_path.exists():
        return {}

    try:
        with open(config_path) as f:
            return json.load(f)
    except json.JSONDecodeError:
        return {}


def save_config(config: Dict[str, Any]) -> None:
    """Save configuration to file."""
    config_path = get_config_path()
    ensure_config_directory()

    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)


def get_config_value(key: str, default: Optional[str] = None) -> Optional[str]:
    """Get a configuration value.

    Checks in order:
    1. Environment variable
    2. Config file
    3. Default value
    """
    # Check environment variable first
    env_key = key.upper()
    if env_value := os.getenv(env_key):
        return env_value

    # Check config file
    config = load_config()
    if value := config.get(key):
        return value

    return default


def set_config_value(key: str, value: str) -> None:
    """Set a configuration value."""
    config = load_config()
    config[key] = value
    save_config(config)


def get_pinecone_api_key() -> str:
    """Get Pinecone API key from config or environment."""
    api_key = get_config_value(
        "pinecone_api_key",
        os.getenv("PINECONE_API_KEY")
    )

    if not api_key:
        raise ValueError(
            "Pinecone API key not found\n"
            "Set with: export PINECONE_API_KEY='your-key'\n"
            "Or run: bash scripts/setup-env.sh"
        )

    return api_key


def get_pinecone_index() -> str:
    """Get Pinecone index name."""
    return get_config_value("pinecone_index", "genai-assistant")


def get_api_url() -> Optional[str]:
    """Get API Gateway URL from config."""
    return get_config_value("api_url")


def get_bedrock_region() -> str:
    """Get Bedrock region."""
    return get_config_value("bedrock_region", "us-east-1")
