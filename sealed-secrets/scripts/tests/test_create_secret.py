"""Offline regression tests; tool stubs use only fictional secret values."""
import base64
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "create-secret.sh"
SECRET = r"FAKE value $HOME `id` % @ \ backslash * -n"
TOOL = r'''#!/usr/bin/env python3
import base64, json, os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["CALL_LOG"], "a") as out:
    out.write(json.dumps([name, args]) + "\n")
if name == "kubectl" and args == ["config", "get-contexts", "-o", "name"]:
    print("lab-context\nother-context")
    sys.exit(0)
data = sys.stdin.buffer.read()
if os.environ.get("FAIL_TOOL") == name:
    print(data.decode(), file=sys.stderr)
    sys.exit(23)
if name == "kubectl":
    key = next(a for a in args if a.startswith("--from-file=")).split("=", 2)[1]
    result = {"apiVersion": "v1", "kind": "Secret", "data": {key: base64.b64encode(data).decode()}}
    print(json.dumps(result))
else:
    if os.environ.get("EMPTY_OUTPUT"):
        sys.exit(0)
    pathlib.Path(os.environ["RECEIVED_SECRET"]).write_bytes(data)
    if os.environ.get("RACE_OUTPUT"):
        pathlib.Path("demo-sealed-secret.yaml").write_text("existing file")
    print("apiVersion: bitnami.com/v1alpha1\nkind: SealedSecret\nspec:\n  encryptedData:\n    password: FAKE-CIPHERTEXT")
'''


class CreateSecretTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.work = self.root / "work"
        self.work.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ["kubectl", "kubeseal"]:
            path = self.bin / name
            path.write_text(TOOL)
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}",
                        CALL_LOG=str(self.root / "calls"),
                        RECEIVED_SECRET=str(self.root / "received"))
        self.args = ["-n", "lab", "-c", "lab-context", "-r", "demo", "-k", "password"]

    def run_script(self, args=None, input_value=SECRET + "\n", trace=False):
        result = subprocess.run(["bash"] + (["-x"] if trace else []) +
                                [str(SCRIPT)] + (self.args if args is None else args),
                                input=input_value, text=True, capture_output=True,
                                cwd=self.work, env=self.env, timeout=15)
        self.assertNotIn(SECRET, result.stdout + result.stderr)
        self.assertNotIn(base64.b64encode(SECRET.encode()).decode(),
                         result.stdout + result.stderr)
        self.assertFalse(list(self.work.glob("*raw-secret*")))
        self.assertFalse(list(self.work.glob(".*sealed-secret.*")))
        return result

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        output = self.work / "demo-sealed-secret.yaml"
        self.assertTrue(output.exists())
        self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)
        raw = json.loads((self.root / "received").read_text())
        self.assertEqual(base64.b64decode(raw["data"]["password"]).decode(), SECRET)
        calls = [json.loads(line) for line in (self.root / "calls").read_text().splitlines()]
        for name, args in calls[1:]:
            self.assertEqual(args[args.index("--context") + 1], "lab-context")
            self.assertEqual(args[args.index("--namespace") + 1], "lab")
            self.assertNotIn("apply", args)
            self.assertNotIn("use-context", args)
            self.assertNotIn(SECRET, args)

    def test_hidden_prompt_preserves_special_characters(self):
        self.assert_success(self.run_script())

    def test_legacy_secret_option_is_not_logged(self):
        self.assert_success(self.run_script(self.args + ["-s", SECRET], ""))

    def test_interactive_prompts(self):
        self.assert_success(self.run_script([], "lab\ndemo\npassword\nlab-context\n" + SECRET + "\n"))

    def test_bash_trace_does_not_expose_secret(self):
        self.assert_success(self.run_script(trace=True))

    def test_tool_failures_leave_no_output(self):
        for name in ["kubectl", "kubeseal"]:
            with self.subTest(tool=name):
                self.env["FAIL_TOOL"] = name
                self.assertNotEqual(self.run_script().returncode, 0)
                self.assertFalse((self.work / "demo-sealed-secret.yaml").exists())

    def test_empty_sealed_output_is_rejected(self):
        self.env["EMPTY_OUTPUT"] = "1"
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertFalse((self.work / "demo-sealed-secret.yaml").exists())

    def test_existing_output_is_preserved(self):
        output = self.work / "demo-sealed-secret.yaml"
        output.write_text("original")
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual(output.read_text(), "original")

    def test_output_created_during_sealing_is_not_overwritten(self):
        self.env["RACE_OUTPUT"] = "1"
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual((self.work / "demo-sealed-secret.yaml").read_text(), "existing file")

    def test_invalid_inputs_and_unknown_context(self):
        for args in [["-n", "../lab"], ["-r", "../demo"], ["-k", "bad/key"],
                     ["-c", "unknown"], ["-z"], ["-r"], ["unexpected"]]:
            with self.subTest(args=args):
                self.assertNotEqual(self.run_script(self.args + args).returncode, 0)
                self.assertFalse((self.work / "demo-sealed-secret.yaml").exists())

    def test_empty_secret_is_rejected(self):
        self.assertNotEqual(self.run_script(input_value="\n").returncode, 0)

    def test_missing_tool_is_reported(self):
        (self.bin / "kubeseal").unlink()
        self.assertNotEqual(self.run_script().returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
