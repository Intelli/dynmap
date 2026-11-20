#!/usr/bin/env bash
# Build Dynmap for Paper 26.3. Requires JDK 21 and JDK 25.
# Output: target/Dynmap-Paper-26.3.jar and Dynmap-Paper-26.3.jar in this directory.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

resolve_java_home() {
  if [[ -n "${JAVA_HOME:-}" ]] && [[ -x "${JAVA_HOME}/bin/java" ]]; then
    if "${JAVA_HOME}/bin/java" -version 2>&1 | head -1 | grep -qE 'version "21'; then
      return 0
    fi
    echo "warning: JAVA_HOME is set but is not JDK 21; trying to find JDK 21" >&2
  fi

  if [[ "$(uname -s)" == "Darwin" ]] && [[ -x /usr/libexec/java_home ]]; then
    if JAVA_21="$(/usr/libexec/java_home -v 21 2>/dev/null)"; then
      export JAVA_HOME="$JAVA_21"
      return 0
    fi
  fi

  for candidate in \
    /Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
    /usr/lib/jvm/java-21-openjdk \
    /usr/lib/jvm/java-21-openjdk-amd64; do
    if [[ -x "${candidate}/bin/java" ]]; then
      export JAVA_HOME="$candidate"
      return 0
    fi
  done

  echo "error: JDK 21 is required. Install JDK 21 or set JAVA_HOME to a JDK 21 install." >&2
  exit 1
}

resolve_java_home
echo "Using JAVA_HOME=${JAVA_HOME}"
./gradlew setup build "$@"

jar="$ROOT/target/Dynmap-Paper-26.3.jar"
if [[ ! -f "$jar" ]]; then
  echo "error: plugin jar not found: $jar" >&2
  exit 1
fi
dest="$ROOT/Dynmap-Paper-26.3.jar"
cp -f "$jar" "$dest"
echo "Installed $(basename "$dest") (Paper 26.3)"
