#!/usr/bin/env bash
# Build Dynmap (Spigot jar and dependencies). Requires JDK 21.
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
exec ./gradlew setup build "$@"
