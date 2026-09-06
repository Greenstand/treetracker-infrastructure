"""Behavioral checks for deployment boundaries, wiring and lifecycle packaging."""
import copy
import gzip
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tarfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts/lib"))
import network
import lifecycle


class Charts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.docs = [d for c in network.COMPONENTS for d in network.render(c)]

    def test_production_wiring(self):
        network.validate(self.docs, profile="production")

    def test_kind_wiring(self):
        docs = [d for c in network.COMPONENTS for d in network.render(c, "kind")]
        network.validate(docs, profile="kind")
        for d in docs:
            if d["kind"] == "Deployment" and d["metadata"]["namespace"] == "hlf-orderer":
                affinity = d["spec"]["template"]["spec"]["affinity"]["podAntiAffinity"]
                self.assertFalse(affinity.get("requiredDuringSchedulingIgnoredDuringExecution"))
                self.assertTrue(affinity.get("preferredDuringSchedulingIgnoredDuringExecution"))

    def test_orderer_groups_cannot_cross_select(self):
        docs = copy.deepcopy(self.docs)
        service = next(d for d in docs if d["kind"] == "Service" and d["metadata"]["name"] == "orderer0")
        del service["spec"]["selector"]["fabric.greenstand.org/channel"]
        with self.assertRaisesRegex(ValueError, "selects 2"):
            network.validate(docs, profile="production")

    def test_volume_reference_failure_detected(self):
        docs = copy.deepcopy(self.docs)
        doc = next(d for d in docs if d["kind"] == "PersistentVolumeClaim"
                   and d["metadata"]["name"] == "raft-orderer-data-0")
        docs.remove(doc)
        with self.assertRaisesRegex(ValueError, "Missing PVC"):
            network.validate(docs, profile="production")

    def test_unpinned_image_rejected(self):
        docs = copy.deepcopy(self.docs)
        next(d for d in docs if d["kind"] == "Deployment")["spec"]["template"]["spec"]["containers"][0]["image"] = "image:latest"
        with self.assertRaisesRegex(ValueError, "Unpinned image"):
            network.validate(docs, profile="production")

    def test_inline_credentials_rejected(self):
        docs = copy.deepcopy(self.docs)
        next(d for d in docs if d["kind"] == "Deployment")["spec"]["template"]["spec"]["containers"][0]["env"].append(
            {"name": "COUCHDB_PASSWORD", "value": "unsafe-test-value"})
        with self.assertRaisesRegex(ValueError, "Inline credential"):
            network.validate(docs, profile="production")

    def test_only_legacy_claims_are_unmounted(self):
        mounted = {v["persistentVolumeClaim"]["claimName"] for d in self.docs
                   if d["kind"] in ("Deployment", "StatefulSet")
                   for v in d["spec"]["template"]["spec"].get("volumes", []) if "persistentVolumeClaim" in v}
        claims = {d["metadata"]["name"] for d in self.docs if d["kind"] == "PersistentVolumeClaim"}
        unused = claims - mounted
        self.assertEqual(len(unused), 8)
        self.assertTrue(all(n.startswith("peer-data-") for n in unused))

    def test_identity_contract_matches_render(self):
        import yaml
        contract = yaml.safe_load((ROOT / "config/required-inputs.yaml").read_text())["inputs"]
        expected = {(r["kind"], r["namespace"], r["name"]): r["keys"] for r in contract}
        self.assertEqual(network.external_inputs(self.docs), expected)

    def test_no_cross_node_override_leak(self):
        result = network.run(["helm", "template", "fabric-peers", ROOT / "k8s/peers", "-n", "hlf-peer-org",
                              "--set-string", "nodes.peer0-cbo.pod.containers.peer.env.CORE_PEER_ID.value=override-only"])
        import yaml
        docs = [d for d in yaml.safe_load_all(result.stdout) if d and d["kind"] == "StatefulSet"]
        ids = {d["metadata"]["name"]: next(e["value"] for e in d["spec"]["template"]["spec"]["containers"][0]["env"]
                                         if e["name"] == "CORE_PEER_ID") for d in docs}
        self.assertEqual(ids.pop("peer0-cbo"), "override-only")
        self.assertTrue(all(k == v for k, v in ids.items()))

    def test_wrong_namespace_refused(self):
        result = network.run(["helm", "template", "fabric-ca", ROOT / "k8s/ca", "-n", "default"], check=False)
        self.assertNotEqual(result.returncode, 0)

    def test_deterministic_external_package(self):
        code = lifecycle.tar_bytes({"connection.json": b'{"tls_required":true}'})
        a = lifecycle.tar_bytes({"code.tar.gz": code, "metadata.json": b'{"type":"external"}'})
        self.assertEqual(a, lifecycle.tar_bytes({"metadata.json": b'{"type":"external"}', "code.tar.gz": code}))
        with tarfile.open(fileobj=io.BytesIO(a), mode="r:gz") as archive:
            self.assertEqual(set(archive.getnames()), {"metadata.json", "code.tar.gz"})
            self.assertTrue(all(m.mtime == 0 for m in archive.getmembers()))

    def test_channel_generation_is_plan_by_default(self):
        result = network.run([sys.executable, ROOT / "scripts/lib/lifecycle.py", "channel", "generate",
                              "--block", "/tmp/fabric-test-not-written.block"])
        self.assertIn("configtxgen", result.stdout)
        self.assertFalse(Path("/tmp/fabric-test-not-written.block").exists())


if __name__ == "__main__":
    unittest.main()
