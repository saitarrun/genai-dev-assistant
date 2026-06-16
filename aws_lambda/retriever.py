import os
from typing import Any, Optional, List, Dict

from pinecone import Pinecone


class PineconeRetriever:
    def __init__(self):
        api_key = os.getenv("PINECONE_API_KEY")
        index_name = os.getenv("PINECONE_INDEX", "genai-assistant")

        if not api_key:
            raise ValueError("PINECONE_API_KEY environment variable not set")

        self.pc = Pinecone(api_key=api_key)
        self.index = self.pc.Index(index_name)

    def retrieve(
        self,
        query_vector: List[float],
        namespace: str,
        top_k: int = 6,
        score_threshold: float = 0.75,
        filter_dict: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """Query Pinecone and return top-k results above score threshold."""
        results = self.index.query(
            vector=query_vector,
            top_k=top_k,
            namespace=namespace,
            include_metadata=True,
        )

        retrieved = []
        for match in results.get("matches", []):
            if match.get("score", 0) < score_threshold:
                continue

            metadata = match.get("metadata", {})
            if filter_dict:
                if not all(metadata.get(k) == v for k, v in filter_dict.items()):
                    continue

            retrieved.append(
                {
                    "id": match.get("id"),
                    "score": match.get("score"),
                    "text": metadata.get("text", ""),
                    "metadata": metadata,
                }
            )

        return retrieved
