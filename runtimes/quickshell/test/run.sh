#!/bin/bash
# Holds the Quickshell runtime to the language's reference implementation.
#
# OwlOracle.java drives tools/owl.jar's own compiler and evaluator with a
# fixed host and prints every evaluated property and drawing call as JSON;
# walk.js does the same walk with Owl.js. They must print the same bytes:
#
#   edge.owl                196 expressions chosen to break a port
#   <widget>.fixture.json   store widgets with the data their sources gave once
#   every store widget      with no source data at all
#
# and `owl check` and Owl.js must accept and reject the same files.
#
# Needs java (17+), javac and node. The expected output is never stored:
# it comes from the jar in this repo, so a new owl.jar is checked as it lands.

set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$here/../../.." && pwd)
jar=$repo/tools/owl.jar
owl=$here/../Owl.js
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

# The fixtures' times are formatted in Berlin, and java's locale starts the
# week on Sunday, as walk.js does.
export TZ=Europe/Berlin
java_opts=(-Duser.timezone=Europe/Berlin -Duser.language=en -Duser.country=US)

javac -cp "$jar" -d "$out" "$here/OwlOracle.java"

failed=0
check() {
  local name=$1 src=$2 fixture=$3
  java "${java_opts[@]}" -cp "$jar:$out" OwlOracle "$src" "$fixture" >"$out/java.json" 2>/dev/null
  node "$here/walk.js" "$owl" "$src" "$fixture" >"$out/js.json" 2>/dev/null
  if cmp -s "$out/java.json" "$out/js.json"; then
    echo "ok - $name"
  else
    echo "not ok - $name"
    diff <(tr ',' '\n' <"$out/java.json") <(tr ',' '\n' <"$out/js.json") | head -10
    failed=1
  fi
}

check "edge cases" "$here/edge.owl" "$here/edge.fixture.json"
for f in "$here"/*.fixture.json; do
  name=$(basename "$f" .fixture.json)
  case $name in edge | base) continue ;; esac
  check "$name with data" "$repo/widgets/simonschubert/$name/widget.owl" "$f"
done
for w in "$repo"/widgets/*/*/widget.owl; do
  check "$(basename "$(dirname "$w")") without data" "$w" "$here/base.fixture.json"
done

# Accepted and rejected alike, with the same message at the same place.
mine=$(node -e '
  const fs = require("fs"), Module = require("module")
  const m = new Module(process.argv[1]); m.filename = process.argv[1]
  m._compile(fs.readFileSync(process.argv[1], "utf8").replace(/^\.pragma library/, "//"), process.argv[1])
  for (const f of process.argv.slice(2)) {
    const src = fs.readFileSync(f, "utf8")
    try { m.exports.compile(src); console.log("OK  " + f) }
    catch (e) { console.log("ERR " + f + ":" + m.exports.formatError(src, e).split("\n")[0]) }
  }' "$owl" "$repo"/widgets/*/*/widget.owl "$here/edge.owl" | sort)
theirs=$(java "${java_opts[@]}" -cp "$jar" dev.omalauncher.widgets.cli.MainKt check "$repo"/widgets/*/*/widget.owl "$here/edge.owl" 2>&1 |
  grep -E '^(ok|ERR)' | sed -E 's/^ok  ([^ ]+).*/OK  \1/' | sort)
if [ "$mine" = "$theirs" ]; then
  echo "ok - owl check and Owl.js agree on every widget"
else
  echo "not ok - owl check and Owl.js disagree"
  diff <(echo "$theirs") <(echo "$mine") | head -10
  failed=1
fi

exit $failed
