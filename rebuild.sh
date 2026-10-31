#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

MODE="rebuild"
ALLOW=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --allow-cleanup) ALLOW="${2:-}"; shift 2 ;;
    --allow-cleanup=*) ALLOW="${1#*=}"; shift ;;
    -h|--help)
      cat <<'EOF'
Usage: rebuild.sh [--check] [--allow-cleanup LIST]

  (default)   Run the Homebrew guard, then darwin-rebuild switch.
  --check     Run the guard only (read-only, no rebuild).
  --allow-cleanup LIST
              Allow a rebuild that removes the named undeclared items.
              LIST is comma-separated; use "formula:name" or "cask:name"
              (or a bare name when unambiguous). Must name exactly the
              undeclared items; zap removes them during activation.
EOF
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" != "check" ]]; then
  ln -sfn "$DIR" ~/.dotfiles
fi

# Fail-closed Homebrew guard: compare installed formulae/casks with the
# declarations evaluated from configuration.nix. Prints undeclared items.
GUARD_PY='
import json, subprocess, sys

def run(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.PIPE)

try:
    leaves = [x for x in run(["brew", "leaves"]).split() if x.strip()]
    casks = [x for x in run(["brew", "list", "--cask"]).split() if x.strip()]
except Exception as e:
    print(f"guard error: could not inventory Homebrew: {e}", file=sys.stderr)
    sys.exit(2)

try:
    brews_json = run(["nix", "eval", "--json", ".#darwinConfigurations.mac.config.homebrew.brews"])
    casks_json = run(["nix", "eval", "--json", ".#darwinConfigurations.mac.config.homebrew.casks"])
    declared_brews = {x["name"] for x in json.loads(brews_json)}
    declared_casks = {x["name"].split("/")[-1] for x in json.loads(casks_json)}
except Exception as e:
    print(f"guard error: could not evaluate declarations: {e}", file=sys.stderr)
    sys.exit(2)

undeclared = []
for name in sorted(set(leaves) - declared_brews):
    undeclared.append(("formula", name))
for name in sorted(set(casks) - declared_casks):
    undeclared.append(("cask", name))

for kind, name in undeclared:
    print(f"{kind}:{name}")
'

UNDECLARED="$(cd "$DIR" && python3 -c "$GUARD_PY")" || {
  echo "brew guard failed (see above)" >&2
  exit 1
}

if [[ -n "$UNDECLARED" ]]; then
  echo "brew guard: undeclared Homebrew items (not in configuration.nix):" >&2
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    kind="${line%%:*}"
    name="${line#*:}"
    printf '  - %s: %s\n' "$kind" "$name" >&2
  done <<< "$UNDECLARED"

  if [[ "$MODE" == "check" ]]; then
    exit 1
  fi

  if [[ -n "$ALLOW" ]]; then
    # Build the set of allowed items from the flag.
    ALLOW_SET="$(python3 - "$ALLOW" "$UNDECLARED" <<'PY'
import sys
allow_raw = sys.argv[1]
undeclared_raw = sys.argv[2]
undeclared = set(undeclared_raw.splitlines())
allowed = set()
for token in allow_raw.split(","):
    token = token.strip()
    if not token:
        continue
    if ":" in token:
        kind, name = token.split(":", 1)
        allowed.add(f"{kind.strip()}:{name.strip()}")
    else:
        # match by name against undeclared
        matches = [u for u in undeclared if u.split(":",1)[1] == token]
        if len(matches) == 1:
            allowed.add(matches[0])
        elif len(matches) > 1:
            print(f"ambiguous name {token!r}: {matches}", file=sys.stderr)
            sys.exit(2)
        else:
            allowed.add(f"?:{token}")
if allowed == undeclared:
    print("ok")
else:
    missing = undeclared - allowed
    extra = allowed - undeclared
    if missing:
        print(f"missing from --allow-cleanup: {sorted(missing)}", file=sys.stderr)
    if extra:
        print(f"not undeclared (nothing to remove): {sorted(extra)}", file=sys.stderr)
    sys.exit(1)
PY
)" || {
      echo "brew guard: --allow-cleanup does not exactly name the undeclared items" >&2
      exit 1
    }
    if [[ "$ALLOW_SET" != "ok" ]]; then
      echo "brew guard: --allow-cleanup validation failed" >&2
      exit 1
    fi
    echo "brew guard: proceeding; zap will remove:" >&2
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '  - %s\n' "$line" >&2
    done <<< "$UNDECLARED"
  else
    echo "brew guard: re-run with --allow-cleanup \"$(echo "$UNDECLARED" | paste -sd, -)\" to permit removal, or declare them in configuration.nix" >&2
    exit 1
  fi
else
  echo "brew guard: ok (no undeclared formulae or casks)"
fi

if [[ "$MODE" == "check" ]]; then
  exit 0
fi

exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac
