"""GitHub integration for auto-indexing repositories."""

import os
import subprocess
import shutil
from pathlib import Path
from typing import List, Optional
import json

import requests


class GitHubClient:
    """Client for GitHub API and repository operations."""

    def __init__(self, token: Optional[str] = None):
        """Initialize GitHub client.

        Args:
            token: GitHub personal access token (optional, for private repos)
        """
        self.token = token or os.getenv("GITHUB_TOKEN")
        self.session = requests.Session()
        if self.token:
            self.session.headers.update({"Authorization": f"token {self.token}"})
        self.base_url = "https://api.github.com"

    def list_org_repos(self, org: str) -> List[dict]:
        """List all repositories in an organization.

        Args:
            org: Organization name

        Returns:
            List of repository dicts
        """
        repos = []
        page = 1
        while True:
            url = f"{self.base_url}/orgs/{org}/repos"
            response = self.session.get(
                url,
                params={"page": page, "per_page": 100, "type": "all"}
            )

            if response.status_code != 200:
                raise ValueError(f"Failed to fetch repos: {response.text}")

            page_repos = response.json()
            if not page_repos:
                break

            repos.extend(page_repos)
            page += 1

        return repos

    def list_user_repos(self, username: str) -> List[dict]:
        """List repositories for a user.

        Args:
            username: GitHub username

        Returns:
            List of repository dicts
        """
        repos = []
        page = 1
        while True:
            url = f"{self.base_url}/users/{username}/repos"
            response = self.session.get(
                url,
                params={"page": page, "per_page": 100, "type": "owner"}
            )

            if response.status_code != 200:
                raise ValueError(f"Failed to fetch repos: {response.text}")

            page_repos = response.json()
            if not page_repos:
                break

            repos.extend(page_repos)
            page += 1

        return repos

    def get_repo(self, owner: str, repo: str) -> dict:
        """Get repository information.

        Args:
            owner: Repository owner
            repo: Repository name

        Returns:
            Repository dict
        """
        url = f"{self.base_url}/repos/{owner}/{repo}"
        response = self.session.get(url)

        if response.status_code != 200:
            raise ValueError(f"Repository not found: {owner}/{repo}")

        return response.json()


class RepositoryIndexer:
    """Index GitHub repositories locally."""

    def __init__(self, cache_dir: str = None):
        """Initialize indexer.

        Args:
            cache_dir: Directory to cache cloned repos (default: ~/.genai-assistant/repos)
        """
        if cache_dir is None:
            cache_dir = str(Path.home() / ".genai-assistant" / "repos")

        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def clone_repo(self, url: str, repo_name: str) -> Path:
        """Clone a GitHub repository.

        Args:
            url: Repository URL
            repo_name: Local name for the repository

        Returns:
            Path to cloned repository
        """
        repo_path = self.cache_dir / repo_name

        # If already cloned, update it
        if repo_path.exists():
            print(f"Updating {repo_name}...")
            subprocess.run(
                ["git", "pull"],
                cwd=str(repo_path),
                capture_output=True,
                check=False
            )
        else:
            print(f"Cloning {repo_name}...")
            subprocess.run(
                ["git", "clone", url, str(repo_path)],
                capture_output=True,
                check=True
            )

        return repo_path

    def get_repo_info(self, repo_path: Path) -> dict:
        """Get information about a local repository.

        Args:
            repo_path: Path to repository

        Returns:
            Dictionary with repo info
        """
        try:
            result = subprocess.run(
                ["git", "config", "--get", "remote.origin.url"],
                cwd=str(repo_path),
                capture_output=True,
                text=True,
                check=True
            )
            remote_url = result.stdout.strip()
        except subprocess.CalledProcessError:
            remote_url = None

        try:
            result = subprocess.run(
                ["git", "rev-parse", "--short", "HEAD"],
                cwd=str(repo_path),
                capture_output=True,
                text=True,
                check=True
            )
            commit_hash = result.stdout.strip()
        except subprocess.CalledProcessError:
            commit_hash = None

        return {
            "name": repo_path.name,
            "path": str(repo_path),
            "remote_url": remote_url,
            "commit": commit_hash,
        }


def index_github_repos(
    org: Optional[str] = None,
    username: Optional[str] = None,
    repos: Optional[List[str]] = None,
    token: Optional[str] = None,
) -> List[tuple]:
    """Index GitHub repositories.

    Args:
        org: Organization name
        username: GitHub username
        repos: Specific repos to index (filter list)
        token: GitHub personal access token

    Returns:
        List of (repo_name, local_path) tuples
    """
    client = GitHubClient(token=token)
    indexer = RepositoryIndexer()

    indexed = []

    if org:
        print(f"Fetching repositories from organization: {org}")
        org_repos = client.list_org_repos(org)

        for repo_info in org_repos:
            repo_name = repo_info["name"]

            # Filter by specific repos if provided
            if repos and repo_name not in repos:
                continue

            # Skip archived repos
            if repo_info.get("archived"):
                print(f"⊘ Skipping archived repo: {repo_name}")
                continue

            print(f"▶ Indexing: {repo_name}")
            repo_path = indexer.clone_repo(repo_info["clone_url"], repo_name)
            indexed.append((repo_name, str(repo_path)))

    if username:
        print(f"Fetching repositories from user: {username}")
        user_repos = client.list_user_repos(username)

        for repo_info in user_repos:
            repo_name = repo_info["name"]

            # Filter by specific repos if provided
            if repos and repo_name not in repos:
                continue

            # Skip archived repos
            if repo_info.get("archived"):
                print(f"⊘ Skipping archived repo: {repo_name}")
                continue

            print(f"▶ Indexing: {repo_name}")
            repo_path = indexer.clone_repo(repo_info["clone_url"], repo_name)
            indexed.append((repo_name, str(repo_path)))

    return indexed
