## Step 2 — history purge (maintainer with admin only)

The keys sit in the history from `bbff87e` (2021-04-29) to `1e87d66^`. This repository has no tags. You must rewrite the history and force-push.

**Requirements on your machine:** `git` (2.24 or newer), `python3`, and `curl`. You do not need to install `git-filter-repo`; Block 1 downloads it.

Run the blocks in order, in one terminal session.

### Block 1 — redact and verify locally (safe; does not push)

This block finds the key values itself and replaces every copy with `REDACTED`. You do not paste any secret.

```bash
set -euo pipefail
REPO=treetracker-infrastructure
URL=https://github.com/Greenstand/$REPO
WORK=/tmp/purge-$REPO
FILE=kubernetes/terraform/environments/variable.tf

rm -rf "$WORK" && mkdir -p "$WORK"
curl -fsSL https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo -o "$WORK/git-filter-repo"
chmod +x "$WORK/git-filter-repo"

git clone --mirror "$URL" "$WORK/$REPO.git"
cd "$WORK/$REPO.git"

# Extract the access_key / secret_key VALUES from every historical version of the file.
# The guards drop Terraform interpolations (${...}) and short placeholders.
git grep -hoE '(access_key|secret_key)[[:space:]]*=[[:space:]]*"[^"]+"' $(git rev-list --all) -- "$FILE" \
  | sed -E 's/.*"([^"]+)".*/\1/' | grep -vE '[$ {}]' | awk 'length>=16' | sort -u > "$WORK/keys.txt"
echo "Found $(wc -l < "$WORK/keys.txt") key value(s) to redact."
test -s "$WORK/keys.txt" || { echo "No keys found; stop and investigate."; exit 1; }

sed 's/$/==>REDACTED/' "$WORK/keys.txt" > "$WORK/replacements.txt"
python3 "$WORK/git-filter-repo" --replace-text "$WORK/replacements.txt"

# Local verify: no key remains on any ref
fail=0
while read -r k; do
  [ -n "$(git log --all -S"$k" --oneline)" ] && { echo "FAIL: a key is still present"; fail=1; }
done < "$WORK/keys.txt"
[ "$fail" -eq 0 ] && echo "OK: all keys removed from history." || exit 1
echo "Rewritten repo is at $WORK/$REPO.git . Review it, then lift branch protection and run Block 2."
```

### Manual gate A — lift branch protection

Lift the branch protection on `master` in the GitHub UI (Settings → Branches), or with your admin token. Record the current rules first, so you can restore them. A protected branch rejects the force-push.

### Block 2 — push the rewrite

```bash
set -euo pipefail
REPO=treetracker-infrastructure
WORK=/tmp/purge-$REPO
cd "$WORK/$REPO.git"

# git-filter-repo removes the origin remote after the rewrite; add it back.
git remote add origin https://github.com/Greenstand/$REPO
git push --force --all
git push --force --tags
echo "Pushed. Now restore branch protection (Manual gate B), then run Block 3."
```

### Manual gate B — restore branch protection

Restore the branch protection on `master` with the same rules you recorded in gate A.

### Block 3 — verify on a fresh clone (done-bar)

```bash
set -euo pipefail
REPO=treetracker-infrastructure
WORK=/tmp/purge-$REPO
V=/tmp/verify-$REPO
rm -rf "$V"
# Use a NORMAL clone, not --mirror. A mirror clone also fetches refs/pull/*,
# which are GitHub-managed read-only refs you cannot rewrite. They would give
# a false failure. A normal clone checks the branches and tags you control.
git clone https://github.com/Greenstand/$REPO "$V" >/dev/null 2>&1
cd "$V"
fail=0
while read -r k; do
  [ -n "$(git log --all -S"$k" --oneline)" ] && { echo "FAIL"; fail=1; }
done < "$WORK/keys.txt"
[ "$fail" -eq 0 ] && echo "PASS: keys gone from branches and tags" || exit 1
```

Verification trap to avoid: do not use `git clone --mirror` to verify. It fetches the `refs/pull/*` refs, which you cannot change, so it always shows a key and reports a false failure.

**Close the open pull requests.** This repository has 14 open PRs. A rewrite changes every commit SHA, so their bases become invalid even though none touch `variable.tf`. Close them and ask the authors to re-create against the rewritten base. After the push, tell contributors to re-clone or run `git reset --hard`.

## Step 3 — residual exposure (maintainer with admin only; manual)

GitHub keeps old commits alive in three places you cannot reach with a push: the `refs/pull/*` refs (about 138 pull requests, open and closed), the cached commit views, and the ~30 forks. The keys are dead, but do the best-effort cleanup:

1. Open a GitHub Support request for this repository. Ask Support to remove the `refs/pull/*/head` copies of the keys, to purge the cached commit views, and to remove the dangling commits from the shared fork-network storage.
2. Send a short notice to the fork owners (30). Ask them to re-sync or delete the fork.
3. Accept the remaining risk. A fork owner who does not act may still serve a dead key from the fork. We record this as an accepted risk.

## Scope

- Rotation is done offline. This PR does not cover rotation.
- Recurrence prevention (secret scanning, `.gitignore` for `*.tfvars`, config templates) is out of scope. Note: an open PR (#295) already expands `.gitignore` for `.tfvars` files.
