#!/usr/bin/env python3
"""Explicit Fabric channel and chaincode operations using operator-owned MSPs."""
import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[2]


def execute(command, apply, env=None):
    print(shlex.join([str(x) for x in command]), flush=True)
    if apply:
        subprocess.run([str(x) for x in command], env=env, check=True)


def tar_bytes(files):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w", format=tarfile.USTAR_FORMAT) as archive:
        for name, payload in sorted(files.items()):
            item = tarfile.TarInfo(name)
            item.size, item.mode, item.mtime = len(payload), 0o644, 0
            archive.addfile(item, io.BytesIO(payload))
    return gzip.compress(buffer.getvalue(), mtime=0)


def peer_env(args, parser):
    for key in ("msp_id", "msp_dir", "peer", "peer_tls_root"):
        if not getattr(args, key):
            parser.error(f"--{key.replace('_', '-')} is required")
    if not Path(args.msp_dir).is_dir() or not Path(args.peer_tls_root).is_file():
        parser.error("MSP directory and peer TLS root must exist outside the repository")
    return dict(os.environ, CORE_PEER_LOCALMSPID=args.msp_id,
                CORE_PEER_MSPCONFIGPATH=str(Path(args.msp_dir).resolve()),
                CORE_PEER_ADDRESS=args.peer, CORE_PEER_TLS_ENABLED="true",
                CORE_PEER_TLS_ROOTCERT_FILE=str(Path(args.peer_tls_root).resolve()))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("domain", choices=["channel", "chaincode"])
    p.add_argument("action", help="channel: generate, join-orderer, join-peer, list-orderer; chaincode: package, install, approve, check, commit, query")
    p.add_argument("--execute", action="store_true", help="Run the displayed command; default is a plan")
    p.add_argument("--channel", choices=["treetracker", "treetracker-v2"], default="treetracker-v2")
    p.add_argument("--block", help="Genesis block path; generated only for a NEW channel")
    p.add_argument("--config-dir", default=str(ROOT / "config"))
    p.add_argument("--orderer", help="Orderer broadcast host:7050 for chaincode lifecycle")
    p.add_argument("--orderer-admin", help="Reachable orderer admin host:9444 for osnadmin")
    p.add_argument("--orderer-tls-root")
    p.add_argument("--admin-cert")
    p.add_argument("--admin-key")
    p.add_argument("--msp-id")
    p.add_argument("--msp-dir")
    p.add_argument("--peer")
    p.add_argument("--peer-tls-root")
    p.add_argument("--name", choices=["tree-contract", "token-contract"])
    p.add_argument("--version", default="1.0")
    p.add_argument("--sequence", type=int, default=1)
    p.add_argument("--package", help="Chaincode package path")
    p.add_argument("--package-id")
    p.add_argument("--label")
    p.add_argument("--address", help="Chaincode service DNS:port embedded in connection.json")
    p.add_argument("--tls-root", help="Chaincode service issuing CA PEM")
    p.add_argument("--signature-policy")
    p.add_argument("--collections-config")
    p.add_argument("--init-required", action="store_true")
    p.add_argument("--endorser", action="append", default=[], help="Commit peer endpoint; repeat in matching order with --endorser-tls-root")
    p.add_argument("--endorser-tls-root", action="append", default=[])
    a = p.parse_args()
    if a.domain == "channel":
        if a.action == "generate":
            if not a.block:
                p.error("generate requires --block")
            if Path(a.block).exists():
                p.error("Refusing to overwrite an existing channel block")
            profile = "TreetrackerV2Channel" if a.channel == "treetracker-v2" else "TreetrackerChannel"
            execute(["configtxgen", "-configPath", a.config_dir, "-profile", profile,
                     "-channelID", a.channel, "-outputBlock", a.block], a.execute)
        elif a.action in ("join-orderer", "list-orderer"):
            if not all([a.orderer_admin, a.orderer_tls_root, a.admin_cert, a.admin_key]):
                p.error("osnadmin requires --orderer-admin, --orderer-tls-root, --admin-cert, --admin-key")
            command = ["osnadmin", "channel", "join" if a.action == "join-orderer" else "list",
                       "-o", a.orderer_admin, "--ca-file", a.orderer_tls_root,
                       "--client-cert", a.admin_cert, "--client-key", a.admin_key,
                       "--channelID", a.channel]
            if a.action == "join-orderer":
                if not a.block or not Path(a.block).is_file():
                    p.error("join-orderer requires an existing --block")
                command += ["--config-block", a.block]
            execute(command, a.execute)
        elif a.action == "join-peer":
            if not a.block or not Path(a.block).is_file():
                p.error("join-peer requires an existing --block")
            execute(["peer", "channel", "join", "-b", a.block], a.execute, peer_env(a, p))
        else:
            p.error("Unknown channel action")
        return
    if a.action == "package":
        if not all([a.package, a.label, a.address, a.tls_root]):
            p.error("package requires --package, --label, --address, --tls-root")
        if not __import__("re").fullmatch(r"[A-Za-z0-9]+(?:[._+-][A-Za-z0-9]+)*", a.label):
            p.error("Invalid Fabric chaincode package label")
        cert = Path(a.tls_root).read_text()
        if "-----BEGIN CERTIFICATE-----" not in cert:
            p.error("--tls-root must be a PEM certificate")
        connection = json.dumps({"address": a.address, "dial_timeout": "10s", "tls_required": True,
                                 "client_auth_required": False, "root_cert": cert}, sort_keys=True).encode()
        metadata = json.dumps({"path": "", "type": "external", "label": a.label}, sort_keys=True).encode()
        payload = tar_bytes({"metadata.json": metadata,
                             "code.tar.gz": tar_bytes({"connection.json": connection})})
        print(f"Package ID: {a.label}:{hashlib.sha256(payload).hexdigest()}")
        if a.execute:
            with open(a.package, "xb") as out:
                out.write(payload)
        else:
            print(f"Would create {a.package}; pass --execute to write")
        return
    env = peer_env(a, p)
    command = ["peer", "lifecycle", "chaincode"]
    if a.action == "install":
        if not a.package or not Path(a.package).is_file():
            p.error("install requires an existing --package")
        command += ["install", a.package]
    elif a.action == "query":
        command += ["querycommitted", "--channelID", a.channel, "--output", "json"]
    elif a.action in ("approve", "check", "commit"):
        if not a.name or a.sequence < 1:
            p.error("A valid --name and positive --sequence are required")
        command += [{"approve": "approveformyorg", "check": "checkcommitreadiness", "commit": "commit"}[a.action],
                    "--channelID", a.channel, "--name", a.name, "--version", a.version,
                    "--sequence", str(a.sequence)]
        if a.signature_policy:
            command += ["--signature-policy", a.signature_policy]
        if a.collections_config:
            command += ["--collections-config", a.collections_config]
        if a.init_required:
            command += ["--init-required"]
        if a.action == "approve":
            if not a.package_id:
                p.error("approve requires --package-id")
            command += ["--package-id", a.package_id]
        if a.action == "check":
            command += ["--output", "json"]
        else:
            if not a.orderer or not a.orderer_tls_root:
                p.error("approve/commit requires --orderer and --orderer-tls-root")
            command += ["-o", a.orderer, "--tls", "--cafile", a.orderer_tls_root]
        if a.action == "commit":
            if not a.endorser or len(a.endorser) != len(a.endorser_tls_root):
                p.error("commit requires matching --endorser and --endorser-tls-root arguments")
            for endpoint, root in zip(a.endorser, a.endorser_tls_root):
                command += ["--peerAddresses", endpoint, "--tlsRootCertFiles", root]
    else:
        p.error("Unknown chaincode action")
    execute(command, a.execute, env)


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
