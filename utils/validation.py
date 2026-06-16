"""Validation and error checking utilities."""

import os
import sys
import json
from pathlib import Path
from typing import Optional, Dict, Any


class ValidationError(Exception):
    """Raised when validation fails."""
    pass


def validate_environment() -> Dict[str, str]:
    """Validate required environment variables and return their values.

    Returns:
        Dict with validated environment variables

    Raises:
        ValidationError if any required variable is missing
    """
    required = {
        "PINECONE_API_KEY": "Pinecone API key",
        "PINECONE_INDEX": "Pinecone index name (default: genai-assistant)",
    }

    missing = []
    env_vars = {}

    for key, description in required.items():
        value = os.getenv(key)
        if key == "PINECONE_INDEX" and not value:
            # Use default
            value = "genai-assistant"
            os.environ[key] = value
        elif not value:
            missing.append(f"  • {key}: {description}")

        if value:
            env_vars[key] = value

    if missing:
        error_msg = "Missing required environment variables:\n" + "\n".join(missing)
        error_msg += "\n\nFix with:\n"
        error_msg += "  export PINECONE_API_KEY='your-api-key'\n"
        error_msg += "  export PINECONE_INDEX='genai-assistant'\n"
        raise ValidationError(error_msg)

    return env_vars


def validate_pinecone_api_key(api_key: str) -> bool:
    """Validate Pinecone API key format.

    Args:
        api_key: The API key to validate

    Returns:
        True if valid, raises ValidationError if not
    """
    if not api_key or len(api_key) < 10:
        raise ValidationError(
            "Invalid Pinecone API key (too short). "
            "Get it from: https://app.pinecone.io/\nClick your name → API keys"
        )
    return True


def validate_file_path(filepath: str, must_exist: bool = True) -> Path:
    """Validate a file path.

    Args:
        filepath: Path to validate
        must_exist: If True, file must exist

    Returns:
        Resolved Path object

    Raises:
        ValidationError if path is invalid
    """
    try:
        path = Path(filepath).resolve()
    except Exception as e:
        raise ValidationError(f"Invalid file path: {filepath}\n{e}")

    if must_exist and not path.exists():
        raise ValidationError(
            f"File does not exist: {filepath}\n\n"
            f"Make sure the path is correct. Use absolute paths like:\n"
            f"  python3 -m ingestion.pipeline --repo ~/my-repo --namespace my-repo"
        )

    if must_exist and path.is_file():
        raise ValidationError(f"Expected directory, got file: {filepath}")

    return path


def validate_namespace(namespace: str) -> bool:
    """Validate Pinecone namespace format.

    Args:
        namespace: The namespace to validate

    Returns:
        True if valid, raises ValidationError if not
    """
    if not namespace or len(namespace) < 1:
        raise ValidationError("Namespace cannot be empty")

    if not namespace.replace("-", "").replace("_", "").isalnum():
        raise ValidationError(
            f"Invalid namespace: '{namespace}'\n"
            f"Use alphanumeric characters, hyphens, and underscores only"
        )

    return True


def validate_json_config(config_path: str) -> Dict[str, Any]:
    """Validate and load JSON configuration file.

    Args:
        config_path: Path to config.json

    Returns:
        Parsed configuration dict

    Raises:
        ValidationError if file is invalid
    """
    path = Path(config_path)

    if not path.exists():
        raise ValidationError(f"Config file not found: {config_path}")

    try:
        with open(path) as f:
            config = json.load(f)
    except json.JSONDecodeError as e:
        raise ValidationError(
            f"Invalid JSON in {config_path}:\n{e}\n\n"
            f"Check the file syntax or run: bash scripts/fix-common-issues.sh"
        )

    return config


def validate_aws_credentials() -> bool:
    """Check if AWS credentials are configured.

    Returns:
        True if valid, raises ValidationError if not
    """
    try:
        import boto3
        sts = boto3.client('sts')
        sts.get_caller_identity()
        return True
    except Exception as e:
        raise ValidationError(
            "AWS credentials not configured or invalid\n\n"
            "Fix with:\n"
            "  aws configure\n\n"
            "You'll need:\n"
            "  • AWS Access Key ID\n"
            "  • Secret Access Key\n"
            "  • Default region: us-east-1\n"
            f"\nError: {e}"
        )


def validate_pinecone_connection(api_key: str, index_name: str = "genai-assistant") -> bool:
    """Test connection to Pinecone.

    Args:
        api_key: Pinecone API key
        index_name: Pinecone index name

    Returns:
        True if connected, raises ValidationError if not
    """
    try:
        from pinecone import Pinecone
    except ImportError:
        raise ValidationError(
            "Pinecone not installed\n\n"
            "Fix with:\n"
            "  pip install pinecone"
        )

    try:
        pc = Pinecone(api_key=api_key)
        index = pc.Index(index_name)
        index.describe_index_stats()
        return True
    except Exception as e:
        error_str = str(e).lower()

        if "401" in error_str or "unauthorized" in error_str:
            raise ValidationError(
                f"Invalid Pinecone API key\n\n"
                f"Get the correct key from:\n"
                f"  https://app.pinecone.io/ → Your name → API keys\n\n"
                f"Then update:\n"
                f"  export PINECONE_API_KEY='your-real-key'\n"
                f"  or edit ~/.genai-assistant/config.json"
            )

        if "not found" in error_str or "does not exist" in error_str:
            raise ValidationError(
                f"Pinecone index '{index_name}' not found\n\n"
                f"Create it at:\n"
                f"  https://app.pinecone.io/ → Create index\n\n"
                f"Settings:\n"
                f"  Name: {index_name}\n"
                f"  Dimensions: 1536\n"
                f"  Metric: cosine"
            )

        raise ValidationError(
            f"Cannot connect to Pinecone: {e}\n\n"
            f"Check:\n"
            f"  • PINECONE_API_KEY is correct\n"
            f"  • Index '{index_name}' exists and is Ready\n"
            f"  • Network connection is working"
        )


def validate_bedrock_access(region: str = "us-east-1") -> bool:
    """Check if Bedrock models are accessible.

    Args:
        region: AWS region

    Returns:
        True if accessible, raises ValidationError if not
    """
    try:
        import boto3
        bedrock = boto3.client('bedrock', region_name=region)
        bedrock.list_foundation_models()
        return True
    except Exception as e:
        raise ValidationError(
            "Bedrock models not accessible in us-east-1\n\n"
            "To enable:\n"
            "  1. Go to AWS Console → Region: us-east-1\n"
            "  2. Search 'Bedrock' → Click 'Bedrock'\n"
            "  3. Click 'Model access' → 'Manage model access'\n"
            "  4. Enable:\n"
            "     • Amazon Titan Embeddings (amazon.titan-embed-text-v2:0)\n"
            "     • Claude 3.5 Haiku (anthropic.claude-3-5-haiku-*)\n"
            "  5. Click 'Save changes'\n"
            "  6. Wait 5-10 minutes for approval\n\n"
            f"Error: {e}"
        )


def print_validation_help(error: ValidationError) -> None:
    """Pretty-print validation error with helpful formatting.

    Args:
        error: The ValidationError to display
    """
    print("\n" + "="*70, file=sys.stderr)
    print("❌ Configuration Error", file=sys.stderr)
    print("="*70, file=sys.stderr)
    print(f"\n{error}\n", file=sys.stderr)
    print("="*70, file=sys.stderr)
    print("Run 'bash scripts/health-check.sh' to diagnose all issues", file=sys.stderr)
    print("="*70 + "\n", file=sys.stderr)
