#!/bin/bash
# Test the ingestion pipeline with a sample repository

set -e

echo "🧪 Testing Ingestion Pipeline"
echo "============================="

# Create temp directory
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Creating test repository in $TMPDIR..."

# Create sample Python files
mkdir -p "$TMPDIR/src"

cat > "$TMPDIR/src/auth.py" << 'EOF'
import hashlib
import jwt

class AuthManager:
    """Manages user authentication and JWT tokens."""

    def __init__(self, secret_key):
        self.secret_key = secret_key

    def hash_password(self, password):
        """Hash a password using SHA256."""
        return hashlib.sha256(password.encode()).hexdigest()

    def verify_password(self, password, hashed):
        """Verify a password against its hash."""
        return self.hash_password(password) == hashed

    def create_token(self, user_id, expires_in=3600):
        """Create a JWT token for the user."""
        payload = {
            'user_id': user_id,
            'exp': int(time.time()) + expires_in
        }
        return jwt.encode(payload, self.secret_key, algorithm='HS256')

    def verify_token(self, token):
        """Verify a JWT token and return the payload."""
        try:
            return jwt.decode(token, self.secret_key, algorithms=['HS256'])
        except jwt.InvalidTokenError:
            return None
EOF

cat > "$TMPDIR/src/database.py" << 'EOF'
import sqlite3
from contextlib import contextmanager

class DatabaseConnection:
    """Manages database connections with connection pooling."""

    def __init__(self, db_path, pool_size=5):
        self.db_path = db_path
        self.pool_size = pool_size
        self.pool = []
        self.create_pool()

    def create_pool(self):
        """Create a pool of database connections."""
        for _ in range(self.pool_size):
            conn = sqlite3.connect(self.db_path)
            self.pool.append(conn)

    @contextmanager
    def get_connection(self):
        """Get a connection from the pool."""
        if not self.pool:
            raise RuntimeError("No connections available")

        conn = self.pool.pop()
        try:
            yield conn
        finally:
            self.pool.append(conn)

    def execute(self, query, params=None):
        """Execute a query and return results."""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            return cursor.fetchall()
EOF

cat > "$TMPDIR/src/api.py" << 'EOF'
from flask import Flask, request, jsonify
from auth import AuthManager
from database import DatabaseConnection

app = Flask(__name__)
auth = AuthManager(secret_key="dev-secret-key")
db = DatabaseConnection("app.db")

@app.route("/api/login", methods=["POST"])
def login():
    """Authenticate user and return JWT token."""
    data = request.json
    username = data.get("username")
    password = data.get("password")

    # Query user from database
    users = db.execute(
        "SELECT id, password_hash FROM users WHERE username = ?",
        (username,)
    )

    if not users:
        return jsonify({"error": "Invalid credentials"}), 401

    user_id, password_hash = users[0]
    if not auth.verify_password(password, password_hash):
        return jsonify({"error": "Invalid credentials"}), 401

    token = auth.create_token(user_id)
    return jsonify({"token": token}), 200

@app.route("/api/user/<int:user_id>", methods=["GET"])
def get_user(user_id):
    """Get user profile information."""
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    payload = auth.verify_token(token)

    if not payload:
        return jsonify({"error": "Unauthorized"}), 401

    users = db.execute(
        "SELECT id, username, email, created_at FROM users WHERE id = ?",
        (user_id,)
    )

    if not users:
        return jsonify({"error": "User not found"}), 404

    return jsonify({
        "id": users[0][0],
        "username": users[0][1],
        "email": users[0][2],
        "created_at": users[0][3]
    }), 200
EOF

# Create markdown documentation
cat > "$TMPDIR/README.md" << 'EOF'
# Test Application

A simple Flask-based authentication and user management system.

## Architecture

### Authentication Module (`src/auth.py`)
Handles password hashing and JWT token generation/verification.

- `AuthManager.hash_password()` — SHA256 password hashing
- `AuthManager.create_token()` — JWT token creation
- `AuthManager.verify_token()` — JWT token verification

### Database Module (`src/database.py`)
Manages SQLite connections with connection pooling for concurrent requests.

- `DatabaseConnection.create_pool()` — Initialize connection pool
- `DatabaseConnection.get_connection()` — Get connection from pool
- `DatabaseConnection.execute()` — Execute query with connection management

### API Module (`src/api.py`)
Flask REST API endpoints for user authentication and profile retrieval.

- `POST /api/login` — Authenticate user, return JWT token
- `GET /api/user/<id>` — Get user profile (requires valid token)

## Setup

```bash
pip install flask pyjwt
python src/api.py
```

## Usage

```bash
# Login
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "secret"}'

# Get user (with token)
curl -H "Authorization: Bearer <token>" \
  http://localhost:5000/api/user/1
```
EOF

echo "✓ Created test repository with 3 modules + docs"
echo ""

# Test dry-run first
echo "Testing ingestion with --dry-run..."
python3 -m ingestion.pipeline \
    --repo "$TMPDIR" \
    --namespace test-repo \
    --dry-run

echo ""
echo "✓ Dry-run successful!"
echo ""

# Ask if user wants to actually ingest
read -p "Do you want to ingest to Pinecone? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping Pinecone ingestion."
    exit 0
fi

echo ""
echo "Ingesting to Pinecone (namespace: test-repo)..."
python3 -m ingestion.pipeline \
    --repo "$TMPDIR" \
    --namespace test-repo

echo ""
echo "✅ Test ingestion complete!"
echo ""
echo "Next: Test querying with:"
echo "  python3 -m cli.ask 'How does authentication work?' --namespace test-repo"
