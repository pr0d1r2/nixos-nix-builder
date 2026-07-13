#!/usr/bin/env bats

sandbox_script() {
    local tmp="$1"
    sed \
        -e 's|/mnt/storage-fast|__FAST__|g' \
        -e 's|/mnt/storage|__STOR__|g' \
        -e 's|/tmp/|__TMP__|g' \
        scripts/build/iso_store_dir.sh |
        sed \
            -e "s|__FAST__|${tmp}/mnt/storage-fast|g" \
            -e "s|__STOR__|${tmp}/mnt/storage|g" \
            -e "s|__TMP__|${tmp}/tmp/|g"
}

@test "prefers /mnt/storage-fast when available" {
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/mnt/storage-fast"
    run sh -c "
        source /dev/stdin <<'SCRIPT'
$(sandbox_script "$tmp")
SCRIPT
    "
    [ "$status" -eq 0 ]
    [[ "$output" = *"$tmp/mnt/storage-fast/nix-builder-iso"* ]]
    rm -rf "$tmp"
}

@test "prefers /mnt/storage over /tmp" {
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/mnt/storage"
    run sh -c "
        source /dev/stdin <<'SCRIPT'
$(sandbox_script "$tmp")
SCRIPT
    "
    [ "$status" -eq 0 ]
    [[ "$output" = *"$tmp/mnt/storage/nix-builder-iso"* ]]
    rm -rf "$tmp"
}

@test "falls back to tmp when no storage dirs exist" {
    tmp="$(mktemp -d)"
    run sh -c "
        source /dev/stdin <<'SCRIPT'
$(sandbox_script "$tmp")
SCRIPT
    "
    [ "$status" -eq 0 ]
    [[ "$output" = *"$tmp/tmp/nix-builder-iso"* ]] # nolocalpath
    rm -rf "$tmp"
}
