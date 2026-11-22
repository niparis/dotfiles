#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix is not installed. Install Determinate Nix first:" >&2
  echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install" >&2
  exit 1
fi

HOSTNAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
case "$HOSTNAME" in
  "Nicolass-MacBook-Pro-950") HOST="mac" ;;
  *Studio*|*studio*) HOST="studio" ;;
  *) echo "Unknown host: $HOSTNAME (no darwinConfiguration). Supported: mac, studio" >&2; exit 1 ;;
esac

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix is not installed. Install Determinate Nix first:" >&2
  echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install" >&2
  exit 1
fi

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

# First activation on a machine without nix-darwin yet.
if ! command -v darwin-rebuild >/dev/null 2>&1; then
  echo "darwin-rebuild not found; doing first activation via nix run..." >&2
  exec sudo nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake "path:${DIR}#${HOST}"
fi

# Fail-closed Homebrew guard: compare installed formulae/casks with the
# declarations evaluated from configuration.nix. Prints undeclared items.
GUARD_PY='
import json, os, subprocess, sys

flake = os.environ.get("FLAKE_DIR", ".")
nix = os.environ.get("NIX", "nix")

def run(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.PIPE)

try:
    brews_json = run([nix, "eval", "--json", f"{flake}#darwinConfigurations.{os.environ.get('HOST','mac')}.config.homebrew.brews"])
    casks_json = run([nix, "eval", "--json", f"{flake}#darwinConfigurations.{os.environ.get('HOST','mac')}.config.homebrew.casks"])
    prefix = run([nix, "eval", "--raw", f"{flake}#darwinConfigurations.{os.environ.get('HOST','mac')}.config.homebrew.prefix"]).strip()
    declared_brews = {x["name"].split("/")[-1] for x in json.loads(brews_json)}
    declared_casks = {x["name"].split("/")[-1] for x in json.loads(casks_json)}
except Exception as e:
    print(f"guard error: could not evaluate declarations: {e}", file=sys.stderr)
    sys.exit(2)

cellar = os.path.join(prefix, "Cellar")
caskroom = os.path.join(prefix, "Caskroom")
if not os.path.isdir(cellar):
    print(f"guard error: Cellar not found at {cellar}", file=sys.stderr)
    sys.exit(2)

installed_on_request = set()
needed = set()
try:
    for name in os.listdir(cellar):
        keg_dir = os.path.join(cellar, name)
        if not os.path.isdir(keg_dir):
            continue
        versions = [v for v in os.listdir(keg_dir) if os.path.isdir(os.path.join(keg_dir, v))]
        if not versions:
            continue
        receipts = []
        for v in versions:
            rp = os.path.join(keg_dir, v, "INSTALL_RECEIPT.json")
            if os.path.exists(rp):
                with open(rp) as f:
                    receipts.append(json.load(f))
        if not receipts:
            print(f"guard error: missing receipt for {name}", file=sys.stderr)
            sys.exit(2)
        if any(r.get("installed_on_request") is True for r in receipts):
            installed_on_request.add(name)
        for r in receipts:
            for dep in r.get("runtime_dependencies") or []:
                full = dep.get("full_name") or dep.get("name")
                if full:
                    needed.add(str(full).split("/")[-1])
except Exception as e:
    print(f"guard error: could not read Cellar receipts: {e}", file=sys.stderr)
    sys.exit(2)

undeclared = []
for name in sorted(installed_on_request - declared_brews - needed):
    undeclared.append(("formula", name))

if os.path.isdir(caskroom):
    try:
        casks = {n for n in os.listdir(caskroom) if os.path.isdir(os.path.join(caskroom, n)) and not n.startswith(".")}
    except Exception as e:
        print(f"guard error: could not list Caskroom: {e}", file=sys.stderr)
        sys.exit(2)
    for name in sorted(casks - declared_casks):
        undeclared.append(("cask", name))
else:
    print(f"guard error: Caskroom not found at {caskroom}", file=sys.stderr)
    sys.exit(2)

for kind, name in undeclared:
    print(f"{kind}:{name}")

'

if command -v brew >/dev/null 2>&1; then
  UNDECLARED="$(cd "$DIR" && FLAKE_DIR="$DIR" HOST="$HOST" python3 -c "$GUARD_PY")" || {
    echo "brew guard failed (see above)" >&2
    exit 1
  }
else
  echo "brew guard: skipped (Homebrew not installed yet)"
  UNDECLARED=""
fi

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

exec sudo darwin-rebuild switch --flake "path:${DIR}#${HOST}"
