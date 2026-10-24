"""Tests for the tiles robots.txt and its CloudFront Function.

Run from this directory: python3 -m unittest -v
Needs: protego (pip install protego) and node.
"""
import json
import pathlib
import re
import subprocess
import unittest
import urllib.robotparser

from protego import Protego

import build

HERE = pathlib.Path(__file__).resolve().parent
ROBOTS = build.read(HERE / "robots.txt")
SITE = "https://tiles.treetracker.org"
SEARCH_ENGINES = ["Googlebot", "Bingbot", "Baiduspider", "YandexBot", "Applebot", "DuckDuckBot"]
OTHER_CRAWLERS = ["AhrefsBot", "Bytespider", "GPTBot", "ClaudeBot", "SomeNewBot"]
UNFILTERED_IMAGES = [
    "/2/1/1.png?icon=ptk-s",
    "/16/30360/31238.png?icon=ptk-b",
]
NOT_FOR_CRAWLERS = [
    "/2/1/1.png?icon=ptk-s&map_name=example",
    "/13/4800/4100.png?icon=ptk-b&userid=5",
    "/13/4800/4100.png?icon=ptk-b&wallet=example",
    "/13/4800/4100.png?icon=ptk-b&timeline=2020-01-01",
    "/13/4800/4100.grid.json?icon=ptk-s",
    "/13/4800/4100.grid.json?icon=ptk-s&map_name=example",
    "/2/1/1.png?map_name=example&icon=ptk-s",  # a new parameter order fails closed
    "/2/1/1.png",
    "/",
]
NODE_RUN = """
const fs = require('fs');
const handler = new Function(fs.readFileSync(process.argv[1], 'utf8') + '\\nreturn handler;')();
const event = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
process.stdout.write(JSON.stringify(handler(event)));
"""


def first_match_allowed(robots, agent, path):
    """A parser that supports "*" and "$" but uses the first matching rule, not the longest."""
    groups, group = [], None
    for line in robots.splitlines():
        key, _, value = line.split("#", 1)[0].partition(":")
        key, value = key.strip().lower(), value.strip()
        if key == "user-agent":
            if group is None or group["rules"]:
                group = {"agents": [], "rules": []}
                groups.append(group)
            group["agents"].append(value.lower())
        elif key in ("allow", "disallow") and group is not None and value:
            pattern = re.escape(value).replace(r"\*", ".*").replace(r"\$", "$")
            group["rules"].append((key == "allow", re.compile(pattern)))
    chosen = next((g for g in groups if agent.lower() in g["agents"]), None)
    chosen = chosen or next(g for g in groups if "*" in g["agents"])
    return next((allow for allow, rule in chosen["rules"] if rule.match(path)), True)


class Rules(unittest.TestCase):
    """RFC 9309 matching (wildcards, longest match), as Google, Bing, and protego implement it."""

    def setUp(self):
        self.parser = Protego.parse(ROBOTS)

    def allowed(self, agent, path):
        return self.parser.can_fetch(SITE + path, agent)

    def test_search_engines_can_load_unfiltered_images(self):
        for agent in SEARCH_ENGINES:
            for path in UNFILTERED_IMAGES:
                with self.subTest(agent=agent, path=path):
                    self.assertTrue(self.allowed(agent, path))

    def test_no_crawler_can_load_other_urls(self):
        for agent in SEARCH_ENGINES + OTHER_CRAWLERS:
            for path in NOT_FOR_CRAWLERS:
                with self.subTest(agent=agent, path=path):
                    self.assertFalse(self.allowed(agent, path))

    def test_other_crawlers_cannot_load_images(self):
        for agent in OTHER_CRAWLERS:
            for path in UNFILTERED_IMAGES:
                with self.subTest(agent=agent, path=path):
                    self.assertFalse(self.allowed(agent, path))


class RulesFirstMatch(unittest.TestCase):
    """A crawler that supports "*" but uses the first matching rule must get the same result."""

    def test_same_result_as_longest_match(self):
        longest = Protego.parse(ROBOTS)
        for agent in SEARCH_ENGINES + OTHER_CRAWLERS:
            for path in UNFILTERED_IMAGES + NOT_FOR_CRAWLERS:
                with self.subTest(agent=agent, path=path):
                    self.assertEqual(first_match_allowed(ROBOTS, agent, path), longest.can_fetch(SITE + path, agent))


class RulesWithoutWildcards(unittest.TestCase):
    """A crawler that reads "*" as a normal character must get nothing (the rules fail closed)."""

    def test_search_engines_get_nothing(self):
        parser = urllib.robotparser.RobotFileParser()
        parser.parse(ROBOTS.splitlines())
        for agent in SEARCH_ENGINES:
            for path in UNFILTERED_IMAGES + NOT_FOR_CRAWLERS:
                with self.subTest(agent=agent, path=path):
                    self.assertFalse(parser.can_fetch(agent, SITE + path))


class Function(unittest.TestCase):
    def test_generated_file_is_current(self):
        self.assertEqual(build.read(HERE / "robots-function.js"), build.render(ROBOTS), "run: python3 build.py")

    def test_function_is_below_the_size_limit(self):
        self.assertLessEqual(len(build.render(ROBOTS).encode("utf-8")), build.SIZE_LIMIT)

    def test_handler_returns_robots_txt(self):
        out = subprocess.run(
            ["node", "-e", NODE_RUN, HERE / "robots-function.js", HERE / "test-event.json"],
            capture_output=True, text=True, check=True,
        )
        response = json.loads(out.stdout)
        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(response["headers"]["content-type"], {"value": "text/plain; charset=utf-8"})
        self.assertEqual(response["headers"]["cache-control"], {"value": "public, max-age=3600"})
        self.assertEqual(response["body"], {"encoding": "text", "data": ROBOTS})


if __name__ == "__main__":
    unittest.main()
