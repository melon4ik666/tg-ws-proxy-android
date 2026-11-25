#!/bin/sh
# Обёртка для сборки на ARM-хосте (Android-chroot, Raspberry Pi, qemu-user).
#
# AGP скачивает aapt2 только под linux-x86_64. На arm64 его можно запустить
# через qemu-x86_64-static. Использование:
#
#   ./gradlew assembleArm64Release \
#     -Pandroid.aapt2FromMavenOverride="$(pwd)/tools/aapt2-qemu.sh"
#
# Путь к настоящему aapt2 ищется в кэше Gradle автоматически; можно задать
# явно через AAPT2_REAL=/path/to/aapt2.
set -eu

if [ -n "${AAPT2_REAL:-}" ]; then
    REAL="$AAPT2_REAL"
else
    # Распаковать из jar-артефакта в кэше Gradle (linux-классификатор, x86-64).
    JAR="$(find "${GRADLE_USER_HOME:-$HOME/.gradle}" /root/gradle-home -type f -name 'aapt2-*-linux.jar' 2>/dev/null | head -n 1)"
    if [ -n "$JAR" ]; then
        CACHE_BIN="/tmp/opencode/aapt2-cache"
        mkdir -p "$CACHE_BIN"
        if [ ! -x "$CACHE_BIN/aapt2" ]; then
            unzip -o -q "$JAR" aapt2 -d "$CACHE_BIN" 2>/dev/null || true
            chmod +x "$CACHE_BIN/aapt2" 2>/dev/null || true
        fi
        [ -x "$CACHE_BIN/aapt2" ] && REAL="$CACHE_BIN/aapt2"
    fi
    if [ -z "$REAL" ]; then
    REAL=""
    for cache in "${GRADLE_USER_HOME:-}" "$HOME/.gradle" /root/gradle-home; do
        [ -n "$cache" ] || continue
        [ -d "$cache/caches" ] || continue
        REAL="$(find "$cache/caches" -type f -path '*transformed/aapt2-*-linux/aapt2' 2>/dev/null | head -n 1)"
        [ -n "$REAL" ] && break
    done
    fi
fi

if [ -z "${REAL:-}" ] || [ ! -x "$REAL" ]; then
    echo "aapt2: не найден бинарник. Запустите любую сборку один раз (он скачается в кэш Gradle)" >&2
    echo "       или укажите AAPT2_REAL=/path/to/aapt2" >&2
    exit 1
fi

QEMU="${QEMU_X86_64:-qemu-x86_64-static}"
exec "$QEMU" "$REAL" "$@"
