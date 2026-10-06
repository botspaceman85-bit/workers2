#!/usr/bin/env bash
set -euo pipefail

PROJECT="${1:?project path required}"
REQUESTED="${2:-}"
PUB="$PROJECT/pubspec.yaml"

python3 - "$PROJECT" "$REQUESTED" <<'PY'
import re, sys, pathlib

project = pathlib.Path(sys.argv[1])
requested = sys.argv[2].strip()
pub = project / "pubspec.yaml"
text = pub.read_text("utf-8", errors="ignore") if pub.exists() else ""

def dart_lower_bound(s):
    m = re.search(r'\b(?:>=\s*)?(\d+)\.(\d+)(?:\.(\d+))?', s)
    return tuple(int(x or 0) for x in m.groups()) if m else None

env = re.search(r'(?ms)^\s*environment\s*:\s*(.*?)(?=^\S|\Z)', text)
sdk = ""
if env:
    m = re.search(r'(?m)^\s*sdk\s*:\s*(.+)$', env.group(1))
    if m: sdk = m.group(1).strip().strip('"\'')
lb = dart_lower_bound(sdk) or (0,0,0)

# Known-good compatibility anchors. For newer Dart constraints, stable is used
# so the project gets the current Flutter/Dart toolchain instead of an obsolete pin.
if requested:
    flutter = requested
    channel = "stable"
elif lb < (2,8,0):
    flutter = "1.22.6"
    channel = "stable"
elif lb < (2,12,0):
    flutter = "2.5.3"
    channel = "stable"
elif lb < (2,17,0):
    flutter = "2.10.5"
    channel = "stable"
elif lb < (3,0,0):
    flutter = "3.7.12"
    channel = "stable"
elif lb < (3,2,0):
    flutter = "3.13.9"
    channel = "stable"
elif lb < (3,3,0):
    flutter = "3.16.9"
    channel = "stable"
elif lb < (3,4,0):
    flutter = "3.19.6"
    channel = "stable"
elif lb < (3,5,0):
    flutter = "3.22.3"
    channel = "stable"
elif lb < (3,6,0):
    flutter = "3.24.5"
    channel = "stable"
elif lb < (3,7,0):
    flutter = "3.27.4"
    channel = "stable"
elif lb < (3,8,0):
    flutter = "3.29.3"
    channel = "stable"
elif lb < (3,9,0):
    flutter = "3.32.8"
    channel = "stable"
else:
    flutter = "stable"
    channel = "stable"

# Read Android Gradle Plugin / Gradle wrapper when present to choose a compatible JVM.
agp_text = ""
for f in [project/"android/build.gradle", project/"android/settings.gradle",
          project/"android/settings.gradle.kts", project/"android/build.gradle.kts"]:
    if f.exists():
        agp_text += f.read_text("utf-8", errors="ignore") + "\n"

gradle = ""
gw = project/"android/gradle/wrapper/gradle-wrapper.properties"
if gw.exists():
    m = re.search(r'gradle-([0-9]+(?:\.[0-9]+){1,2})-(?:bin|all)\.zip', gw.read_text(errors="ignore"))
    if m: gradle = m.group(1)

def ver(v):
    try: return tuple(int(x) for x in v.split(".")[:3])
    except: return (0,0,0)

agp = ""
m = re.search(r'(?:com\.android\.tools\.build:gradle[:=]\s*[\'"]?|id\s*\(?[\'"]com\.android\.application[\'"].*?version\s*[\'"])(\d+(?:\.\d+){1,2})', agp_text, re.S)
if m: agp = m.group(1)

if ver(agp) >= (8,0,0) or ver(gradle) >= (8,0,0) or (flutter not in ("stable",) and ver(flutter) >= (3,16,0)):
    java = "17"
elif ver(gradle) and ver(gradle) < (6,7,0):
    java = "8"
else:
    java = "11"

print(f"FLUTTER_VERSION={flutter}")
print(f"FLUTTER_CHANNEL={channel}")
print(f"JAVA_VERSION={java}")
PY
