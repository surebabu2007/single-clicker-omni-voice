#!/usr/bin/env python3
"""
Pre-downloads the OmniVoice model from HuggingFace.

Features:
- Resumable: interrupted downloads continue from where they stopped
- Mirror fallback: tries hf-mirror.com if huggingface.co is unreachable
- Progress: shows download progress via huggingface_hub
- Exit codes: 0 = success, 1 = failure (for .bat error handling)
"""
import sys
import os

MODEL_ID = "k2-fsa/OmniVoice"

# Try primary HuggingFace endpoint first, then mirror
ENDPOINTS = [
    None,                        # Default: huggingface.co
    "https://hf-mirror.com",     # Mirror for restricted regions
]

# Skip non-model files to reduce download size
IGNORE_PATTERNS = [
    "*.md",
    "*.gitattributes",
    ".gitignore",
    "*.txt",
]


def attempt_download(endpoint=None):
    """Attempt to download the model from a given HF endpoint."""
    if endpoint:
        os.environ["HF_ENDPOINT"] = endpoint
        print(f"  Trying mirror: {endpoint}", flush=True)
    else:
        os.environ.pop("HF_ENDPOINT", None)
        print("  Trying: huggingface.co", flush=True)

    try:
        from huggingface_hub import snapshot_download
        local_path = snapshot_download(
            repo_id=MODEL_ID,
            repo_type="model",
            ignore_patterns=IGNORE_PATTERNS,
        )
        print(f"  Downloaded to: {local_path}", flush=True)
        return True
    except KeyboardInterrupt:
        print("\n  Download interrupted by user.", file=sys.stderr)
        print("  Re-run the installer to resume.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"  Failed: {type(e).__name__}: {e}", file=sys.stderr, flush=True)
        return False


def main():
    cache_dir = os.path.join(os.path.expanduser("~"), ".cache", "huggingface", "hub")
    print(f"Model ID  : {MODEL_ID}", flush=True)
    print(f"Cache dir : {cache_dir}", flush=True)
    print(f"Disk usage: approx. 3-4 GB on first run", flush=True)
    print(flush=True)

    for i, endpoint in enumerate(ENDPOINTS):
        if attempt_download(endpoint):
            print(flush=True)
            print("Model download complete.", flush=True)
            sys.exit(0)

        if i < len(ENDPOINTS) - 1:
            print("  Trying next endpoint...", flush=True)
            print(flush=True)

    print(flush=True)
    print("ERROR: All download attempts failed.", file=sys.stderr)
    print("Possible causes:", file=sys.stderr)
    print("  - No internet connection", file=sys.stderr)
    print("  - Insufficient disk space (need ~4 GB free)", file=sys.stderr)
    print("  - Both HuggingFace endpoints unreachable", file=sys.stderr)
    print(file=sys.stderr)
    print("Re-run the installer to resume - downloads pick up where they left off.", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
