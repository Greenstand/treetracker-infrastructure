#!/usr/bin/env python3
"""Import operator-prepared identities from outside Git; never print Secret values."""
import argparse
import base64
import json
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
from network import COMPONENTS, ROOT, external_inputs, render


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", required=True,
                        help="External directory: <namespace>/<object-name>/<key-name>")
    parser.add_argument("--component", choices=list(COMPONENTS) + ["all"], default="all")
    parser.add_argument("--context")
    parser.add_argument("--overrides-dir")
    parser.add_argument("--apply", action="store_true", help="Create missing inputs; refuses to overwrite existing identities")
    parser.add_argument("--skip-existing", action="store_true", help="Keep existing objects after checking their required key names")
    args = parser.parse_args()
    source = Path(args.input_dir).resolve()
    if source == ROOT or ROOT in source.parents:
        parser.error("Keep identity input directories outside this repository")
    if args.apply and not args.context:
        parser.error("--apply requires --context")
    components = list(COMPONENTS) if args.component == "all" else [args.component]
    docs = [d for c in components for d in render(c, overrides=args.overrides_dir)]
    prepared = []
    for (kind, ns, name), keys in external_inputs(docs).items():
        data = {}
        for key in keys:
            path = source / ns / name / key
            payload = path.read_bytes()
            if not payload:
                raise ValueError(f"Empty identity input: {path}")
            if kind == "Secret" and path.stat().st_mode & 0o077:
                raise ValueError(f"Secret input must be owner-only: {path}")
            data[key] = base64.b64encode(payload).decode() if kind == "Secret" else payload.decode()
        doc = {"apiVersion": "v1", "kind": kind, "metadata": {"name": name, "namespace": ns}, "data": data}
        if kind == "Secret":
            doc["type"] = "kubernetes.io/dockerconfigjson" if ".dockerconfigjson" in keys else "Opaque"
        prepared.append(doc)
        print(f"Validated {kind} {ns}/{name}: {', '.join(keys)}")
    if args.apply:
        # Check every destination before creating the first object. Rotations need a separate workflow.
        missing = []
        for doc in prepared:
            meta = doc["metadata"]
            result = subprocess.run(["kubectl", "--context", args.context, "-n", meta["namespace"],
                                     "get", doc["kind"], meta["name"], "--ignore-not-found", "-o", "name"],
                                    text=True, capture_output=True, check=True)
            if result.stdout.strip():
                if not args.skip_existing:
                    raise ValueError(f"Refusing to overwrite {doc['kind']} {meta['namespace']}/{meta['name']}")
                keys = subprocess.run(["kubectl", "--context", args.context, "-n", meta["namespace"],
                                       "get", doc["kind"], meta["name"], "-o",
                                       'go-template={{range $key, $value := .data}}{{$key}}{{"\\n"}}{{end}}'],
                                      text=True, capture_output=True, check=True)
                if not set(doc["data"]).issubset(keys.stdout.splitlines()):
                    raise ValueError(f"Existing identity has missing keys: {meta['namespace']}/{meta['name']}")
                print(f"Keeping existing {doc['kind']} {meta['namespace']}/{meta['name']}")
            else:
                missing.append(doc)
        for doc in missing:
            # create (not apply) also refuses a concurrent identity creation.
            subprocess.run(["kubectl", "--context", args.context, "create", "-f", "-"],
                           input=json.dumps(doc), text=True, check=True)
    else:
        print("No inputs created; use --context and --apply when ready")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
