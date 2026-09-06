#!/usr/bin/env python3
"""Render, inspect and deploy the six Fabric Helm releases. No implicit cluster writes."""
import argparse
import collections
import json
from pathlib import Path
import re
import subprocess
import sys

import yaml

ROOT = Path(__file__).resolve().parents[2]
COMPONENTS = {
    "storage": "hlf-ca", "ca": "hlf-ca", "couchdb": "hlf-peer-org",
    "orderer": "hlf-orderer", "peers": "hlf-peer-org", "chaincode": "hlf-peer-org",
}


def run(args, *, data=None, check=True):
    return subprocess.run([str(a) for a in args], input=data, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=check)


def helm_args(component, profile, overrides=None):
    args = ["--namespace", COMPONENTS[component]]
    chart = ROOT / "k8s" / component
    if profile == "kind":
        args += ["-f", chart / "values-kind.yaml"]
    if overrides:
        path = Path(overrides) / f"{component}.yaml"
        if path.is_file():
            args += ["-f", path]
    return args


def render(component, profile="production", overrides=None):
    result = run(["helm", "template", f"fabric-{component}", ROOT / "k8s" / component,
                  *helm_args(component, profile, overrides)])
    docs = [d for d in yaml.safe_load_all(result.stdout) if d]
    for doc in docs:
        doc["metadata"].setdefault("namespace", COMPONENTS[component])
    return docs


def external_inputs(docs):
    """Return only external object names and required key names, never values."""
    provided = {(d["kind"], d["metadata"]["namespace"], d["metadata"]["name"]) for d in docs}
    refs = collections.defaultdict(set)
    for d in docs:
        if d["kind"] not in ("Deployment", "StatefulSet"):
            continue
        ns = d["metadata"]["namespace"]
        pod = d["spec"]["template"]["spec"]
        for c in pod.get("containers", []) + pod.get("initContainers", []):
            for e in c.get("env", []):
                for key, kind in (("secretKeyRef", "Secret"), ("configMapKeyRef", "ConfigMap")):
                    ref = e.get("valueFrom", {}).get(key)
                    if ref:
                        refs[kind, ns, ref["name"]].add(ref["key"])
        for v in pod.get("volumes", []):
            for key, kind, field in (("secret", "Secret", "secretName"),
                                     ("configMap", "ConfigMap", "name")):
                if key in v:
                    ref = v[key]
                    refs[kind, ns, ref[field]].update(i["key"] for i in ref.get("items", []))
                    for c in pod.get("containers", []):
                        for mount in c.get("volumeMounts", []):
                            if mount["name"] == v["name"] and mount.get("subPath"):
                                refs[kind, ns, ref[field]].add(mount["subPath"])
                    if "current-root" in v["name"] or "current-msp-root" == v["name"]:
                        refs[kind, ns, ref[field]].add("current-ca.pem")
        for ref in pod.get("imagePullSecrets", []):
            refs["Secret", ns, ref["name"]].add(".dockerconfigjson")
    return {k: sorted(v) for k, v in sorted(refs.items()) if k not in provided}


def validate(docs, *, profile, full=True):
    errors = []
    identities = set()
    by_kind = collections.defaultdict(list)
    for d in docs:
        kind, ns, name = d["kind"], d["metadata"]["namespace"], d["metadata"]["name"]
        identity = (kind, ns, name)
        if identity in identities:
            errors.append(f"Duplicate object: {identity}")
        identities.add(identity)
        by_kind[kind].append(d)
        if ns not in set(COMPONENTS.values()):
            errors.append(f"Out-of-scope namespace: {ns}")
        if kind not in {"Deployment", "StatefulSet", "Service", "ConfigMap",
                        "PersistentVolumeClaim", "ServiceAccount", "NetworkPolicy", "PodDisruptionBudget"}:
            errors.append(f"Out-of-scope kind: {kind}")
        if any(k in d["metadata"] for k in ("uid", "resourceVersion", "managedFields", "creationTimestamp")):
            errors.append(f"Cluster metadata: {identity}")
    workloads = by_kind["Deployment"] + by_kind["StatefulSet"]
    if full:
        counts = collections.Counter(d["spec"]["template"]["metadata"]["labels"].get(
            "fabric.treetracker.io/component") for d in workloads)
        if counts != {"ca": 5, "orderer": 10, "peers": 8, "couchdb": 8, "chaincode": 2}:
            errors.append(f"Unexpected component counts: {dict(counts)}")
        if len(by_kind["PersistentVolumeClaim"]) != 39:
            errors.append("Expected exactly 39 PVCs")
    for d in workloads:
        name, ns = d["metadata"]["name"], d["metadata"]["namespace"]
        spec, pod = d["spec"], d["spec"]["template"]["spec"]
        labels = spec["template"]["metadata"]["labels"]
        if spec["replicas"] != 1:
            errors.append(f"Identity replicated: {name}")
        if any(labels.get(k) != v for k, v in spec["selector"]["matchLabels"].items()):
            errors.append(f"Broken workload selector: {name}")
        if pod.get("automountServiceAccountToken") is not False:
            errors.append(f"API token enabled: {name}")
        if ("ServiceAccount", ns, pod.get("serviceAccountName")) not in identities:
            errors.append(f"Missing service account: {name}")
        if spec.get("volumeClaimTemplates"):
            errors.append(f"Duplicate PVC ownership via StatefulSet: {name}")
        volumes = {v["name"]: v for v in pod.get("volumes", [])}
        for c in pod.get("containers", []) + pod.get("initContainers", []):
            if not re.search(r"@sha256:[0-9a-f]{64}$", c["image"]):
                errors.append(f"Unpinned image: {name}/{c['name']}")
            if not c.get("resources", {}).get("requests") or not c.get("resources", {}).get("limits"):
                errors.append(f"Missing resources: {name}/{c['name']}")
            if not c.get("readinessProbe") or not c.get("livenessProbe"):
                errors.append(f"Missing health probes: {name}/{c['name']}")
            security = c.get("securityContext", {})
            if security.get("allowPrivilegeEscalation") is not False:
                errors.append(f"Privilege escalation allowed: {name}/{c['name']}")
            env = {e["name"]: e for e in c.get("env", [])}
            if len(env) != len(c.get("env", [])):
                errors.append(f"Duplicate environment variables: {name}")
            for e in env.values():
                if ("value" in e) == ("valueFrom" in e):
                    errors.append(f"Invalid environment variable: {name}/{e['name']}")
                if re.search(r"PASSWORD|BOOTSTRAP_USER", e["name"]) and "value" in e:
                    errors.append(f"Inline credential: {name}/{e['name']}")
            for mount in c.get("volumeMounts", []):
                if mount["name"] not in volumes:
                    errors.append(f"Missing volume for mount: {name}/{mount['name']}")
            if labels.get("fabric.treetracker.io/component") == "orderer":
                if env["ORDERER_ADMIN_TLS_ENABLED"].get("value") != "true":
                    errors.append(f"Orderer admin TLS disabled: {name}")
        for v in volumes.values():
            if "hostPath" in v:
                errors.append(f"Node path in workload: {name}")
            if "persistentVolumeClaim" in v and full:
                if ("PersistentVolumeClaim", ns, v["persistentVolumeClaim"]["claimName"]) not in identities:
                    errors.append(f"Missing PVC: {name}/{v['name']}")
            if "configMap" in v:
                ref = v["configMap"]
                cm = next((cm for cm in by_kind["ConfigMap"] if cm["metadata"]["namespace"] == ns
                           and cm["metadata"]["name"] == ref["name"]), None)
                if cm:
                    for item in ref.get("items", []):
                        if item["key"] not in cm.get("data", {}):
                            errors.append(f"Missing ConfigMap key: {name}/{item['key']}")
    for s in by_kind["Service"]:
        selector = s["spec"].get("selector", {})
        matches = [d for d in workloads if d["metadata"]["namespace"] == s["metadata"]["namespace"]
                   and all(d["spec"]["template"]["metadata"]["labels"].get(k) == v
                           for k, v in selector.items())]
        expected = 5 if "headless" in s["metadata"]["name"] else 1
        if len(matches) != expected:
            errors.append(f"Service {s['metadata']['name']} selects {len(matches)}, expected {expected}")
        for port in s["spec"]["ports"]:
            for d in matches:
                ports = [p for c in d["spec"]["template"]["spec"]["containers"] for p in c.get("ports", [])]
                target = port.get("targetPort", port["port"])
                if not any(target == p.get("name") or target == p.get("containerPort") for p in ports):
                    errors.append(f"Unresolved service target: {s['metadata']['name']}/{target}")
    for pvc in by_kind["PersistentVolumeClaim"]:
        if pvc["metadata"].get("annotations", {}).get("helm.sh/resource-policy") != "keep":
            errors.append(f"Unprotected PVC: {pvc['metadata']['name']}")
        if "volumeName" in pvc["spec"]:
            errors.append("PVC bound to old cluster volume")
    if profile == "production" and full and len(by_kind["NetworkPolicy"]) != 5:
        errors.append("Missing component network policies")
    if errors:
        raise ValueError("\n".join(errors))
    return dict(sorted((k, len(v)) for k, v in by_kind.items() if v))


def live_preflight(docs, context, profile, *, ownership=False, components=()):
    errors = []
    base = ["kubectl", "--context", context, "--request-timeout=20s"]
    run(base + ["cluster-info"])
    for (kind, ns, name), keys in external_inputs(docs).items():
        # The API response contains data, but kubectl emits KEY NAMES ONLY to this process.
        result = run(base + ["-n", ns, "get", kind, name, "-o",
                            'go-template={{range $key, $value := .data}}{{$key}}{{"\\n"}}{{end}}'], check=False)
        if result.returncode:
            errors.append(f"Missing/unreadable {kind} {ns}/{name}")
        else:
            missing = set(keys) - set(result.stdout.splitlines())
            if missing:
                errors.append(f"{kind} {ns}/{name} missing keys: {', '.join(sorted(missing))}")
    classes = {d["spec"]["storageClassName"] for d in docs if d["kind"] == "PersistentVolumeClaim"}
    for name in classes:
        result = run(base + ["get", "storageclass", name, "-o", "json"], check=False)
        if result.returncode:
            errors.append(f"Missing StorageClass {name}")
            continue
        sc = json.loads(result.stdout)
        if profile == "production":
            if sc.get("reclaimPolicy") != "Retain":
                errors.append(f"StorageClass {name} must use Retain")
            if sc.get("volumeBindingMode") != "WaitForFirstConsumer":
                errors.append(f"StorageClass {name} must use WaitForFirstConsumer")
            if sc.get("provisioner") in ("rancher.io/local-path", "kubernetes.io/no-provisioner"):
                errors.append(f"StorageClass {name} is local, not production CSI storage")
    if "storage" not in components:
        claims = {(d["metadata"]["namespace"], v["persistentVolumeClaim"]["claimName"])
                  for d in docs if d["kind"] in ("Deployment", "StatefulSet")
                  for v in d["spec"]["template"]["spec"].get("volumes", []) if "persistentVolumeClaim" in v}
        for ns, name in sorted(claims):
            result = run(base + ["-n", ns, "get", "pvc", name, "-o", "name"], check=False)
            if result.returncode:
                errors.append(f"Missing PVC {ns}/{name}; install storage first")
    if profile == "production" and "orderer" in components:
        nodes = json.loads(run(base + ["get", "nodes", "-o", "json"]).stdout)["items"]
        ready = [n for n in nodes if not n["spec"].get("unschedulable")
                 and not any(t.get("effect") == "NoSchedule" for t in n["spec"].get("taints", []))
                 and any(c["type"] == "Ready" and c["status"] == "True" for c in n["status"]["conditions"])]
        if len(ready) < 5:
            errors.append("Production orderer anti-affinity needs at least five schedulable Ready nodes")
    if ownership:
        for component in components:
            for d in render(component, profile, ARGS.overrides_dir):
                ns, name = d["metadata"]["namespace"], d["metadata"]["name"]
                result = run(base + ["-n", ns, "get", d["kind"], name, "--ignore-not-found", "-o", "json"], check=False)
                if result.returncode:
                    errors.append(f"Cannot inspect ownership: {d['kind']} {ns}/{name}")
                elif result.stdout.strip():
                    meta = json.loads(result.stdout)["metadata"]
                    annotations = meta.get("annotations", {})
                    if (annotations.get("meta.helm.sh/release-name") != f"fabric-{component}"
                        or annotations.get("meta.helm.sh/release-namespace") != COMPONENTS[component]
                        or meta.get("labels", {}).get("app.kubernetes.io/managed-by") != "Helm"):
                        errors.append(f"Existing {d['kind']} {ns}/{name} has another owner; see migration guide")
    if errors:
        raise ValueError("\n".join(errors))


def main():
    global ARGS
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("action", choices=["render", "validate", "preflight", "deploy", "test"])
    p.add_argument("--profile", choices=["production", "kind"], default="production")
    p.add_argument("--component", choices=list(COMPONENTS) + ["all"], default="all")
    p.add_argument("--context", help="Required for any cluster access; never uses an implicit context")
    p.add_argument("--overrides-dir", help="Directory containing optional <component>.yaml value overrides")
    p.add_argument("--apply", action="store_true", help="Explicitly install/upgrade; deploy otherwise renders only")
    p.add_argument("--live", action="store_true", help="Check external prerequisites using read-only kubectl")
    p.add_argument("--channel", default="treetracker-v2", choices=["treetracker", "treetracker-v2"])
    ARGS = args = p.parse_args()
    components = list(COMPONENTS) if args.component == "all" else [args.component]
    docs = [d for c in components for d in render(c, args.profile, args.overrides_dir)]
    if args.action == "render" or (args.action == "deploy" and not args.apply):
        sys.stdout.write(yaml.safe_dump_all(docs, sort_keys=False))
    elif args.action == "validate":
        for component in components:
            result = run(["helm", "lint", ROOT / "k8s" / component, "--strict",
                          *helm_args(component, args.profile, args.overrides_dir)])
            print(result.stdout.strip())
        print(json.dumps(validate(docs, profile=args.profile, full=args.component == "all"), indent=2))
    elif args.action == "preflight":
        for (kind, ns, name), keys in external_inputs(docs).items():
            print(f"{kind}\t{ns}\t{name}\t{','.join(keys)}")
        if args.live:
            if not args.context:
                p.error("--live requires --context")
            live_preflight(docs, args.context, args.profile, components=components)
            print("Live prerequisites passed")
    elif args.action == "deploy":
        if not args.context:
            p.error("--apply requires --context")
        validate(docs, profile=args.profile, full=args.component == "all")
        live_preflight(docs, args.context, args.profile, ownership=True, components=components)
        for ns in sorted({d["metadata"]["namespace"] for d in docs}):
            result = run(["kubectl", "--context", args.context, "get", "namespace", ns,
                          "--ignore-not-found", "-o", "name"])
            if not result.stdout.strip():
                run(["kubectl", "--context", args.context, "create", "namespace", ns])
        for component in components:
            # --wait on storage deadlocks with WaitForFirstConsumer until workloads exist.
            command = ["helm", "upgrade", "--install", f"fabric-{component}", ROOT / "k8s" / component,
                       "--kube-context", args.context, "--timeout", "15m", "--history-max", "10",
                       *helm_args(component, args.profile, args.overrides_dir)]
            if component != "storage":
                command += ["--wait"]
            print(f"Deploying {component} into {args.context}/{COMPONENTS[component]}", flush=True)
            subprocess.run([str(a) for a in command], check=True)
    elif args.action == "test":
        if not args.context:
            p.error("test requires --context")
        failures = []
        for d in docs:
            if d["kind"] not in ("Deployment", "StatefulSet"):
                continue
            name, ns = d["metadata"]["name"], d["metadata"]["namespace"]
            result = run(["kubectl", "--context", args.context, "--request-timeout=20s", "-n", ns,
                          "get", d["kind"], name, "-o", "json"], check=False)
            live = json.loads(result.stdout) if result.returncode == 0 else {}
            status = live.get("status", {})
            if result.returncode or status.get("readyReplicas", 0) != 1 or status.get("observedGeneration", 0) < live.get("metadata", {}).get("generation", 1):
                failures.append(f"Not ready: {ns}/{name}")
            else:
                print(f"Ready: {ns}/{name}")
                if d["kind"] == "StatefulSet" and status.get("currentRevision") != status.get("updateRevision"):
                    failures.append(f"Peer update awaiting manual restart: {name}")
        hashes = set()
        config = yaml.safe_load((ROOT / "config/network-config.yaml").read_text())
        for name in config["channels"][args.channel]["peers"]:
            result = run(["kubectl", "--context", args.context, "-n", "hlf-peer-org", "exec",
                          f"{name}-0", "-c", "peer", "--", "peer", "channel", "getinfo", "-c", args.channel], check=False)
            match = re.search(r"Blockchain info:\s*(\{.*\})", result.stdout + result.stderr)
            if result.returncode or not match:
                failures.append(f"Channel read failed: {name}/{args.channel}")
            else:
                info = json.loads(match.group(1))
                hashes.add((info["height"], info["currentBlockHash"]))
                print(f"{name}: height={info['height']} hash={info['currentBlockHash']}")
        if len(hashes) != 1:
            failures.append("Participating peer ledger heights/hashes do not agree")
        if failures:
            raise ValueError("\n".join(failures))
        print("Read-only readiness/channel checks passed; no transaction was submitted")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or str(exc), file=sys.stderr)
        sys.exit(1)
    except (ValueError, FileNotFoundError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
