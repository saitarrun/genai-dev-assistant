import json
import os
import sys
from pathlib import Path
from typing import Optional

import click
import requests
from rich.console import Console
from rich.markdown import Markdown
from rich.table import Table

console = Console()


def get_api_url() -> str:
    """Get API Gateway URL from env or config file."""
    if api_url := os.getenv("API_GATEWAY_URL"):
        return api_url

    config_path = Path.home() / ".genai-assistant" / "config.json"
    if config_path.exists():
        try:
            with open(config_path) as f:
                config = json.load(f)
                if api_url := config.get("api_url"):
                    return api_url
        except Exception:
            pass

    return "http://localhost:3001"


@click.command()
@click.argument("question", type=str)
@click.option("--namespace", required=True, type=str, help="Pinecone namespace for the repo")
@click.option("--top-k", default=6, type=int, help="Number of documents to retrieve")
@click.option("--api-url", type=str, help="Override API Gateway URL")
def ask(question: str, namespace: str, top_k: int, api_url: Optional[str] = None):
    """Ask a question about your codebase."""
    if not api_url:
        api_url = get_api_url()

    api_url = api_url.rstrip("/")
    endpoint = f"{api_url}/ask"

    payload = {
        "question": question,
        "namespace": namespace,
        "top_k": top_k,
    }

    try:
        response = requests.post(endpoint, json=payload, timeout=30)
    except requests.ConnectionError:
        console.print(
            f"[red]Error:[/red] Could not connect to API at {endpoint}"
        )
        console.print("Make sure the Lambda is deployed and API_GATEWAY_URL is set correctly")
        raise SystemExit(1)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise SystemExit(1)

    if response.status_code != 200:
        try:
            error_data = response.json()
            error_msg = error_data.get("error", "Unknown error")
        except Exception:
            error_msg = response.text
        console.print(f"[red]Error:[/red] {error_msg}")
        raise SystemExit(1)

    try:
        data = response.json()
    except json.JSONDecodeError:
        console.print(f"[red]Error:[/red] Invalid JSON response", file=__stderr__)
        raise SystemExit(1)

    answer = data.get("answer", "")
    sources = data.get("sources", [])

    console.print(Markdown("## Answer"))
    console.print(Markdown(answer))

    if sources:
        console.print("\n[bold]Sources:[/bold]")
        table = Table(show_header=True, header_style="bold")
        table.add_column("File", style="cyan")
        table.add_column("Language", style="magenta")
        table.add_column("Relevance", style="green")

        for source in sources:
            table.add_row(
                source.get("file_path", "unknown"),
                source.get("language", "unknown"),
                f"{source.get('score', 0):.2%}",
            )

        console.print(table)


if __name__ == "__main__":
    ask()
