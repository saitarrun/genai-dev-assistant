import json
import os
from typing import Any, Dict

from aws_lambda.agent import CodeQAAgent

agent = CodeQAAgent()


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """AWS Lambda handler for /ask endpoint."""
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON in request body"}),
        }

    question = body.get("question", "").strip()
    namespace = body.get("namespace", "").strip()
    top_k = body.get("top_k", 6)

    if not question:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing 'question' field"}),
        }

    if not namespace:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing 'namespace' field"}),
        }

    try:
        result = agent.run(question=question, namespace=namespace, top_k=top_k)
        return {
            "statusCode": 200,
            "body": json.dumps(result),
            "headers": {"Content-Type": "application/json"},
        }
    except Exception as e:
        error_msg = str(e)
        if os.getenv("DEBUG"):
            import traceback
            error_msg += "\n" + traceback.format_exc()

        return {
            "statusCode": 500,
            "body": json.dumps({"error": error_msg}),
            "headers": {"Content-Type": "application/json"},
        }
