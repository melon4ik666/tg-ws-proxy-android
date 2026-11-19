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
    CACHE="${GRADLE_USER_HOME:-$HOME/.gradle}/caches"
    REAL="$(find "$CACHE" -type f -path '*transformed/aapt2-*-linux/aapt2' 2>/dev/null | head -n 1)"
fi

if [ -z "${REAL:-}" ] || [ ! -x "$REAL" ]; then
    echo "aapt2: не найден бинарник. Запустите любую сборку один раз (он скачается в кэш Gradle)" >&2
    echo "       или укажите AAPT2_REAL=/path/to/aapt2" >&2
    exit 1
fi

QEMU="${QEMU_X86_64:-qemu-x86_64-static}"
exec "$QEMU" "$REAL" "$@"
