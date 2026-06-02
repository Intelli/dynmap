#!/usr/bin/env bash
# Build Dynmap (Paper plugin jar). Requires JDK 21.
# Output: target/Dynmap-*-spigot.jar and Dynmap-Paper-<mc>.jar in this directory.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Map bukkit-helper module ids (e.g. 121-11) to Minecraft versions (e.g. 1.21.11).
module_id_to_mc_version() {
  local mod="$1" a b
  if [[ "$mod" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    a="${BASH_REMATCH[1]}"
    b="${BASH_REMATCH[2]}"
    printf '%s.%s.%s\n' "${a:0:1}" "${a:1}" "$b"
  elif [[ "$mod" =~ ^([0-9]+)$ ]]; then
    a="${BASH_REMATCH[1]}"
    printf '%s.%s\n' "${a:0:1}" "${a:1}"
  else
    return 1
  fi
}

resolve_max_paper_mc_version() {
  local mod version best=""
  while IFS= read -r mod; do
    version="$(module_id_to_mc_version "$mod")" || continue
    if [[ -z "$best" ]] || [[ "$(printf '%s\n%s\n' "$best" "$version" | sort -V | tail -1)" == "$version" ]]; then
      best="$version"
    fi
  done < <(grep -oE 'bukkit-helper-[0-9]+(-[0-9]+)?' "$ROOT/settings.gradle" | sed 's/^bukkit-helper-//')
  if [[ -z "$best" ]]; then
    echo "error: could not determine max Paper MC version from settings.gradle" >&2
    exit 1
  fi
  printf '%s\n' "$best"
}

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

shopt -s nullglob
jars=("$ROOT/target"/Dynmap-*-spigot.jar)
shopt -u nullglob
if ((${#jars[@]} == 0)); then
  echo "error: plugin jar not found in target/ (expected Dynmap-*-spigot.jar)" >&2
  exit 1
fi
jar="$(ls -t "${jars[@]}" | head -1)"
mc_version="$(resolve_max_paper_mc_version)"
dest="$ROOT/Dynmap-Paper-${mc_version}.jar"
rm -f "$ROOT"/Dynmap-Paper-*.jar "$ROOT"/Dynmap-*-spigot.jar
cp -f "$jar" "$dest"
echo "Installed $(basename "$dest") (latest supported MC ${mc_version})"
