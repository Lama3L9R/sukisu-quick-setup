#!/usr/bin/bash


function log() {
    echo "[setup-kpm.sh] $@"
}
SELF_DIR=$(git -C $(dirname $0) rev-parse --show-toplevel)

if ! [ -f "scripts/patch_kpm" ]; then
    log "No patch_kpm! downloading..."
    
    TAG=$(jq -r 'map(select(.prerelease)) | first | .tag_name' <<< $(curl -L --silent https://api.github.com/repos/ShirkNeko/SukiSU_KernelPatch_patch/releases))
    log "Latest tag is: $TAG"

    curl -Ls -o "scripts/patch_kpm" "https://github.com/ShirkNeko/SukiSU_KernelPatch_patch/releases/download/$TAG/patch_linux"

    if [ $? -eq 0 ]; then
        log "Download ok"
    else
        log "Download fail ($?)! abort!"
        exit 1
    fi

    if [[ $(stat -c %s "scripts/patch_linux") -lt 1024 ]]; then
        log "Error! downloaded file corrupted (file too small)! abort!"
        exit 1
    fi

    chmod +x "scripts/patch_kpm"
    if [ $? -eq 0 ]; then
        log "Set permission ok"
    else
        log "Failed to set permission! abort!"
        exit 1
    fi
fi


if ! grep -q "CONFIG_KPM" arch/arm64/configs/gki_defconfig; then
    log "Adding CONFIG_KPM=y"
    echo "CONFIG_KPM=y" >> arch/arm64/configs/gki_defconfig
fi

if ! grep -q "kpmpatch" arch/arm64/boot/Makefile; then
    log "Adding auto kpm patch"
    patch -p1 < $SELF_DIR/patches/02-add-auto-kpm-patch.patch
fi
