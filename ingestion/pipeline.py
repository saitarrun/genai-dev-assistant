import os
from pathlib import Path

import click
from pinecone import Pinecone
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from ingestion.chunker import chunk_repository
from ingestion.embedder import get_embeddings

console = Console()


@click.command()
@click.option("--repo", required=True, type=str, help="Path to the repository to index")
@click.option("--namespace", required=True, type=str, help="Pinecone namespace for this repo")
@click.option("--dry-run", is_flag=True, help="Show chunks without embedding/upserting")
def ingest(repo: str, namespace: str, dry_run: bool):
    """Ingest a repository into Pinecone."""
    repo = str(Path(repo).resolve())

    if not Path(repo).is_dir():
        console.print(f"[red]Error: Repository path does not exist: {repo}[/red]")
        raise SystemExit(1)

    console.print(f"[cyan]Chunking repository: {repo}[/cyan]")

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console,
    ) as progress:
        task = progress.add_task("Chunking files...", total=None)
        documents = chunk_repository(repo, namespace)
        progress.update(task, completed=True)

    console.print(f"[green]✓[/green] Chunked into {len(documents)} documents")

    if dry_run:
        console.print("\n[bold]Sample chunks (--dry-run):[/bold]")
        for i, doc in enumerate(documents[:3]):
            console.print(f"\n[cyan]Chunk {i}[/cyan] ({doc.metadata['file_path']})")
            console.print(f"{doc.page_content[:200]}...")
        return

    api_key = os.getenv("PINECONE_API_KEY")
    if not api_key:
        console.print(
            "[red]Error: PINECONE_API_KEY environment variable not set[/red]"
        )
        raise SystemExit(1)

    console.print("\n[cyan]Initializing Bedrock embeddings...[/cyan]")
    embeddings = get_embeddings()

    console.print("[cyan]Connecting to Pinecone...[/cyan]")
    pc = Pinecone(api_key=api_key)
    index = pc.Index("genai-assistant")

    console.print(f"[cyan]Embedding and upserting to namespace '{namespace}'...[/cyan]")

    batch_size = 100
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console,
    ) as progress:
        task = progress.add_task("Upserting vectors...", total=len(documents))

        for i in range(0, len(documents), batch_size):
            batch = documents[i : i + batch_size]
            texts = [doc.page_content for doc in batch]

            vectors = embeddings.embed_documents(texts)

            records = []
            for doc, vector in zip(batch, vectors):
                records.append(
                    (
                        f"{doc.metadata['file_path']}#{doc.metadata['chunk_index']}",
                        vector,
                        doc.metadata,
                        doc.page_content,
                    )
                )

            index.upsert(
                vectors=records,
                namespace=namespace,
            )

            progress.update(task, advance=len(batch))

    console.print(f"[green]✓[/green] Successfully ingested {len(documents)} documents")


if __name__ == "__main__":
    ingest()
