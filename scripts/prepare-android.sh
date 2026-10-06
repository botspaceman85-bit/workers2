#!/usr/bin/env bash
set -euo pipefail
PROJECT="${1:?project path required}"

if [ -d "$PROJECT/android" ]; then
  mkdir -p "$PROJECT/android"
  touch "$PROJECT/android/gradle.properties"
  grep -q '^android.useAndroidX=' "$PROJECT/android/gradle.properties" || echo 'android.useAndroidX=true' >> "$PROJECT/android/gradle.properties"
  grep -q '^android.enableJetifier=' "$PROJECT/android/gradle.properties" || echo 'android.enableJetifier=true' >> "$PROJECT/android/gradle.properties"
fi

# Flutter tooling is responsible for the SDK's own Gradle integration.
# Do not blindly rewrite AGP/Kotlin versions: old applications can depend on them.
if [ -d "$PROJECT/android" ]; then
  echo "Android project detected."
  if [ -f "$PROJECT/android/gradle/wrapper/gradle-wrapper.properties" ]; then
    grep distributionUrl "$PROJECT/android/gradle/wrapper/gradle-wrapper.properties" || true
  fi
fi

# Accept Android SDK licenses where the runner exposes sdkmanager.
if command -v yes >/dev/null 2>&1 && [ -n "${ANDROID_HOME:-}" ] && [ -x "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" ]; then
  yes | "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
fi
