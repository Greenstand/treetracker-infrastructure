# cdn-tiles

robots.txt for the map tile hosts `tiles.treetracker.org` and `tiles1` to `tiles4.treetracker.org`. The five hosts are one CloudFront distribution. A CloudFront Function on the cache behavior `/robots.txt` returns the file at the edge. The request does not go to the cache or to the tile server.

## Rules

- Search engines (Googlebot, Bingbot, Baiduspider, YandexBot, Applebot, DuckDuckBot) can load unfiltered map images: `/<z>/<x>/<y>.png?icon=<value>` with no other query value. map.treetracker.org pages show these images.
- No crawler may load filtered tiles (a second query value, for example `map_name`, `wallet`, `userid`), `.grid.json` files, or other paths.
- All other crawlers: `Disallow: /`.
- The rules fail closed. A crawler that does not support `*` matches only `Disallow: /`. If the tile URL changes (for example a new parameter before `icon`), search engines also lose the images until robots.txt changes.

## Files

| File | Purpose |
|---|---|
| `robots.txt` | The rules. This is the only file to edit by hand. |
| `build.py` | Writes `robots-function.js` from `robots.txt`. `--check` exits 1 if the generated file is not current. |
| `robots-function.js` | The CloudFront Function (runtime `cloudfront-js-2.0`, event type viewer request). Generated. |
| `test_robots.py` | Tests: the rules with an RFC 9309 parser (protego) and with a parser without wildcard support, the generated file, and the function output (runs the function with `node`). |
| `test-event.json` | The event for a CloudFront Function test (`aws cloudfront test-function`). |
| `.gitattributes` | LF line ends in every checkout, so the served body stays byte-equal to `robots.txt`. |

## Test

```sh
pip install protego
python3 -m unittest -v
```

The tests also need `node`. The workflow `.github/workflows/cdn-tiles.yaml` runs `build.py --check` and the tests on each PR that changes `cdn-tiles/`.

## Change robots.txt

1. Edit `robots.txt` and add cases to `test_robots.py`.
2. Run `python3 build.py`, then the tests.
3. Open a PR, get a review, merge.
4. An AWS admin updates the CloudFront Function from the merged `robots-function.js`, tests it with `test-event.json`, and publishes it. The publish changes the robots.txt at the edge at once (no CloudFront cache). Clients can keep their copy for up to 1 hour (`cache-control: max-age=3600`).
5. Check `https://tiles.treetracker.org/robots.txt`.

## Deployment

- The tiles distribution has a cache behavior `/robots.txt` with the cache policy `Managed-CachingDisabled` and this function as the viewer request function. The default behavior does not change.
- Rollback: remove the cache behavior `/robots.txt`. Then `/robots.txt` goes to the tile server again.

## Notes

- AWS WAF checks a request before the function runs. A crawler that the web ACL blocks also gets 403 for robots.txt.
- Crawlers keep a copy of robots.txt for up to 24 hours (RFC 9309). A change takes effect after their next fetch.
- The distribution itself is not in code yet.
