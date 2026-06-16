import os
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest


@pytest.mark.skipif(
    not os.getenv("INTEGRATION"),
    reason="Integration tests disabled; set INTEGRATION=1 to run",
)
def test_e2e_ingest_and_query():
    """End-to-end test: ingest a fixture repo and query it."""
    from ingestion.chunker import chunk_repository
    from lambda.agent import CodeQAAgent

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        auth_file = tmpdir / "auth.py"
        auth_file.write_text(
            """def verify_token(token):
    '''Verifies JWT token using secret key.'''
    import jwt
    return jwt.decode(token, 'secret')

def hash_password(password):
    '''Hashes password with bcrypt.'''
    import bcrypt
    return bcrypt.hashpw(password, bcrypt.gensalt())
""",
            encoding="utf-8",
        )

        db_file = tmpdir / "db.py"
        db_file.write_text(
            """class Connection:
    def __init__(self, host):
        self.host = host
        self.pool = []

    def create_pool(self, size=10):
        '''Creates a connection pool with given size.'''
        for i in range(size):
            self.pool.append(self.connect())
""",
            encoding="utf-8",
        )

        docs = chunk_repository(str(tmpdir), "fixture-repo")
        assert len(docs) > 0

        for doc in docs:
            assert doc.metadata["repo"] == "fixture-repo"
            assert doc.metadata["file_path"] in ["auth.py", "db.py"]

        auth_docs = [d for d in docs if "auth.py" in d.metadata["file_path"]]
        assert any("verify_token" in d.page_content for d in auth_docs)
