import json
import os
import sys
from typing import Optional, Any, Dict

from langchain_aws import BedrockEmbeddings, ChatBedrock
from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
from langchain.callbacks.base import BaseCallbackHandler

from aws_lambda.retriever import PineconeRetriever


class DebugCallbackHandler(BaseCallbackHandler):
    """Logs debug info when DEBUG=1."""

    def on_llm_start(self, serialized, prompts, **kwargs):
        if os.getenv("DEBUG"):
            debug_log = os.path.expanduser("~/.genai-assistant/debug.log")
            os.makedirs(os.path.dirname(debug_log), exist_ok=True)
            with open(debug_log, "a") as f:
                f.write(f"LLM Prompt tokens: {len(prompts[0]) if prompts else 0}\n")

    def on_llm_end(self, response, **kwargs):
        if os.getenv("DEBUG"):
            debug_log = os.path.expanduser("~/.genai-assistant/debug.log")
            with open(debug_log, "a") as f:
                f.write(f"LLM completed\n")


def format_docs(docs):
    """Format retrieved documents for the prompt."""
    return "\n\n".join(
        f"File: {doc.metadata.get('file_path', 'unknown')}\n"
        f"Content:\n{doc.page_content}"
        for doc in docs
    )


class CodeQAAgent:
    def __init__(self):
        self.embeddings = BedrockEmbeddings(
            model_id="amazon.titan-embed-text-v2:0",
            region_name="us-east-1",
        )
        self.retriever = PineconeRetriever()
        self.llm = ChatBedrock(
            model_id="anthropic.claude-3-5-haiku-20241022",
            region_name="us-east-1",
            temperature=0,
        )

        self.system_prompt = """You are an expert code analyst helping developers understand their codebase.

When answering questions:
1. Always cite the specific file paths where you found the information
2. Provide concrete code examples when relevant
3. If the provided context doesn't contain enough information to answer the question, explicitly say "I don't have enough context to answer this question thoroughly" instead of guessing
4. Format your answer clearly with sections and code blocks as appropriate

Context from the codebase:
{context}"""

        self.prompt = ChatPromptTemplate.from_template(
            self.system_prompt + "\n\nQuestion: {question}"
        )

    def run(
        self,
        question: str,
        namespace: str,
        top_k: int = 6,
    ) -> Dict[str, Any]:
        """Run the QA agent and return answer with sources."""
        verbose = os.getenv("VERBOSE", "").lower() in ("1", "true")

        query_vector = self.embeddings.embed_query(question)

        docs = self.retriever.retrieve(
            query_vector=query_vector,
            namespace=namespace,
            top_k=top_k,
            score_threshold=0.75,
        )

        if not docs:
            return {
                "answer": "I couldn't find relevant information in the codebase to answer this question.",
                "sources": [],
            }

        context = "\n\n".join(
            f"[{doc['metadata'].get('file_path', 'unknown')}]\n{doc['text']}"
            for doc in docs
        )

        chain = self.prompt | self.llm | StrOutputParser()

        if verbose:
            sys.stderr.write(f"Retrieved {len(docs)} documents:\n")
            for doc in docs:
                sys.stderr.write(
                    f"  - {doc['metadata'].get('file_path')}: score={doc['score']:.3f}\n"
                )

        answer = chain.invoke({"question": question, "context": context})

        sources = [
            {
                "file_path": doc["metadata"].get("file_path", "unknown"),
                "score": float(doc.get("score", 0)),
                "language": doc["metadata"].get("language", "unknown"),
            }
            for doc in docs
        ]

        return {
            "answer": answer,
            "sources": sources,
        }
