#!/bin/bash
set -e

if [ -z "$USER" ];then
    export USER="$(id -un)"
fi
export LC_ALL=C
export GAPPS_SOURCES_PATH=vendor/opengapps/sources/

## set defaults

rom_fp="$(date +%y%m%d)"

myname="$(basename "$0")"
if [[ $(uname -s) = "Darwin" ]];then
    jobs=$(sysctl -n hw.ncpu)
elif [[ $(uname -s) = "Linux" ]];then
    jobs=$(nproc)
fi

if [[ ${partition_layout_map[${pieces[1]}]} == *"evox"* || *"pixel"* && ${gapps_selection_map[${pieces[2]}]} == *"gapps"* ]]; then
echo "GApps on this ROM aren't supported this way, please use the vanilla variant to include gapps"
exit 1
fi

if [[ ${partition_layout_map[${pieces[1]}]} == *"evox"* || *"pixel"* && ${gapps_selection_map[${pieces[2]}]} == *"arm64"* ]]; then
export TARGET_GAPPS_ARCH=arm64
echo The ROM you are building is $1
echo GApps variant has been set to $TARGET_GAPPS_ARCH
fi

if [[ partition_layout_map[${pieces[1]}]} == *"evox"* || *"pixel"* && ${gapps_selection_map[${pieces[2]}]} != *"arm"* ]]; then
export TARGET_GAPPS_ARCH=arm
echo The ROM you are building is $1
echo GApps variant has been set to $TARGET_GAPPS_ARCH
fi

## handle command line arguments
read -p "Do you want to sync? (y/N) " choice

function help() {
    cat <<EOF
Syntax:

  $myname [-j 2] <rom type> <variant>...

Options:

  -j   number of parallel make workers (defaults to $jobs)

ROM types:

  carbon7
  carbon8
  lineage160
  lineage170
  rr7
  rr10
  pixel90
  pixel90plus
  pixel100
  evox2
  evox3
  potato9
  potato10
  crdroid90
  crdroid100
  aex9
  aex10
  havoc9
  havoc10
  du9
  du10

Variants are dash-joined combinations of (in order):
* processor type
  * "arm" for ARM 32 bit
  * "arm64" for ARM 64 bit
  * "a64" for ARM 32 bit system with 64 bit binder
* A or A/B partition layout ("aonly" or "ab")
* GApps selection
  * "vanilla" to not include GApps
  * "gapps" to include opengapps
  * "go" to include gapps go
  * "floss" to include floss
* SU selection ("su" or "nosu")
* Build variant selection (optional)
  * "eng" for eng build
  * "user" for prod build
  * "userdebug" for debug build (default)

for example:

* arm-aonly-vanilla-nosu-user
* arm64-ab-gapps-su
* a64-aonly-go-nosu
EOF
}

function get_rom_type() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            carbon7)
                mainrepo="https://github.com/CarbonROM/android.git"
                mainbranch="cr-7.0"
                localManifestBranch="android-9.0"
                treble_generate="carbon"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            carbon8)
                mainrepo="https://github.com/CarbonROM/android.git"
                mainbranch="cr-8.0"
                localManifestBranch="android-10.0"
                treble_generate="carbon"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            lineage160)
                mainrepo="https://github.com/LineageOS/android.git"
                mainbranch="lineage-16.0"
                localManifestBranch="android-9.0"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            lineage170)
                mainrepo="https://github.com/LineageOS/android.git"
                mainbranch="lineage-17.0"
                localManifestBranch="android-10.0"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            rr7)
                mainrepo="https://github.com/RR-ASB/platform_manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate="rr"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            rr10)
                mainrepo="https://github.com/ResurrectionRemix/platform_manifest.git"
                mainbranch="ten-los"
                localManifestBranch="android-10.0"
                treble_generate="rr"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            pixel90)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate="aosp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            pixel90plus)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="pie-plus"
                localManifestBranch="android-9.0"
                treble_generate="aosp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            pixel100)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="ten"
                localManifestBranch="android-10.0"
                treble_generate="aosp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            evox2)
                mainrepo="https://github.com/Evolution-X-ASB/platform_manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate="aosp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            evox3)
                mainrepo="https://github.com/EvoX-temp/manifest.git"
                mainbranch="ten"
                localManifestBranch="android-10.0"
                treble_generate="aosp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            potato9)
                mainrepo="https://github.com/PotatoProject/manifest.git"
                mainbranch="baked-release"
                localManifestBranch="android-9.0"
                treble_generate="potato"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            potato10)
                mainrepo="https://github.com/PotatoProject/manifest.git"
                mainbranch="croquette-release"
                localManifestBranch="android-10.0"
                treble_generate="potato"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            crdroid90)
                mainrepo="https://github.com/crdroidandroid/android.git"
                mainbranch="9.0"
                localManifestBranch="android-9.0"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            crdroid100)
                mainrepo="https://github.com/crdroidandroid/android.git"
                mainbranch="10.0"
                localManifestBranch="android-10.0"
                treble_generate="crdroid"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            aex9)
                mainrepo="https://github.com/AospExtended/manifest.git"
                mainbranch="9.x"
                localManifestBranch="android-9.0"
                treble_generate="aex"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            aex10)
                mainrepo="https://github.com/AospExtended/manifest.git"
                mainbranch="10.x"
                localManifestBranch="android-10.0"
                treble_generate="aex"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            havoc9)
                mainrepo="https://github.com/Havoc-OS/android_manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate="havoc"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            havoc10)
                mainrepo="https://github.com/Havoc-OS/android_manifest.git"
                mainbranch="ten"
                localManifestBranch="android-10.0"
                treble_generate="havoc"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            du9)
		mainrepo="https://github.com/DirtyUnicorns/android_manifest.git"
		mainbranch="p9x"
		localManifestBranch="android-9.0"
		treble_generate="du"
		extra_make_options="WITHOUT_CHECK_API=true"
		;;
            du10)
		mainrepo="https://github.com/DirtyUnicorns/android_manifest.git"
		mainbranch="q10x"
		localManifestBranch="android-10.0"
		treble_generate="du"
		extra_make_options="WITHOUT_CHECK_API=true"
	esac
        shift
    done
}

function parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j)
                jobs="$2";
                shift;
                ;;
        esac
        shift
    done
}

declare -A partition_layout_map
partition_layout_map[aonly]=a
partition_layout_map[ab]=b

declare -A gapps_selection_map
gapps_selection_map[vanilla]=v
gapps_selection_map[gapps]=g
gapps_selection_map[go]=o
gapps_selection_map[floss]=f

declare -A su_selection_map
su_selection_map[su]=S
su_selection_map[nosu]=N

function parse_variant() {
    local -a pieces
    IFS=- pieces=( $1 )

    local processor_type=${pieces[0]}
    local partition_layout=${partition_layout_map[${pieces[1]}]}
    local gapps_selection=${gapps_selection_map[${pieces[2]}]}
    local su_selection=${su_selection_map[${pieces[3]}]}
    local build_type_selection=${pieces[4]}

    if [[ -z "$processor_type" || -z "$partition_layout" || -z "$gapps_selection" || -z "$su_selection" ]]; then
        >&2 echo "Invalid variant '$1'"
        >&2 help
        exit 2
    fi

    echo "treble_${processor_type}_${partition_layout}${gapps_selection}${su_selection}-${build_type_selection}"
}

declare -a variant_codes
declare -a variant_names
function get_variants() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            *-*-*-*-*)
                variant_codes[${#variant_codes[*]}]=$(parse_variant "$1")
                variant_names[${#variant_names[*]}]="$1"
                ;;
            *-*-*-*)
                variant_codes[${#variant_codes[*]}]=$(parse_variant "$1-userdebug")
                variant_names[${#variant_names[*]}]="$1"
                ;;
        esac
        shift
    done
}

## function that actually do things

function init_release() {
    mkdir -p release/"$rom_fp"
}

function init_main_repo() {
    repo init -u "$mainrepo" -b "$mainbranch"
}

function clone_or_checkout() {
    local dir="$1"
    local repo="$2"

    if [[ -d "$dir" ]];then
        (
            cd "$dir"
            git fetch
            git reset --hard
            git checkout origin/"$localManifestBranch"
        )
    else
        git clone https://github.com/phhusson/"$repo" "$dir" -b "$localManifestBranch"
    fi
}

function clone_or_checkout2() {
    local dir="$1"
    local repo="$2"

    if [[ -d "$dir" ]];then
        (
            cd "$dir"
            git fetch
            git reset --hard
            git checkout origin/"$localManifestBranch"
        )
    else
        git clone https://github.com/ExpressLuke/"$repo" "$dir" -b "$localManifestBranch"
    fi
}

function init_local_manifest() {
    clone_or_checkout2 .repo/local_manifests treble_manifest
}

function init_patches() {
    if [[ -n "$treble_generate" ]]; then
        clone_or_checkout2 patches treble_patches

        # We don't want to replace from AOSP since we'll be applying
        # patches by hand
        rm -f .repo/local_manifests/replace.xml

        # Remove exfat entry from local_manifest if it exists in ROM manifest 
        if grep -rqF exfat .repo/manifests || grep -qF exfat .repo/manifest.xml;then
            sed -i -E '/external\/exfat/d' .repo/local_manifests/manifest.xml
        fi

        if [[ $1 == *"evox"* || *"pixel"* ]]; then
            echo Removing phh gapps manifests
            rm -rf .repo/local_manifests/opengapps.xml
	    rm -rf .repo/local_manifests/pe_gapps.xml
        fi
    fi
}

function sync_repo() {
    repo sync -c -j "$jobs" -f --force-sync --no-tag --no-clone-bundle --optimized-fetch --prune
}

function fix_missings() {
	if [[ "$localManifestBranch" == *"9"* ]]; then
		# fix kernel source missing (on pie)
		sed 's;.*KERNEL_;//&;' -i vendor/*/build/soong/Android.bp 2>/dev/null || true
		mkdir -p device/sample/etc
		wget -O apns-full-conf.xml -P device/sample/etc https://github.com/LineageOS/android_vendor_lineage/raw/lineage-16.0/prebuilt/common/etc/apns-conf.xml 2>/dev/null
		
	fi
	if [[ "$localManifestBranch" == *"10"* ]]; then
		# fix kernel source missing (on Q)
		sed 's;.*KERNEL_;//&;' -i vendor/*/build/soong/Android.bp 2>/dev/null || true
		mkdir -p device/sample/etc
		wget -O apns-full-conf.xml -P device/sample/etc https://github.com/LineageOS/android_vendor_lineage/raw/lineage-17.0/prebuilt/common/etc/apns-conf.xml 2>/dev/null
		mkdir -p device/generic/common/nfc
		wget -O libnfc-nci.conf -P device/generic/common/nfc https://github.com/ExpressLuke/treble_experimentations/raw/master/files/libnfc-nci.conf
		sed -i '/Copies the APN/,/include $(BUILD_PREBUILT)/{/include $(BUILD_PREBUILT)/ s/.*/ /; t; d}' vendor/*/prebuilt/common/Android.mk 2>/dev/null || true
	fi
}

function patch_things() {
    if [[ -n "$treble_generate" ]]; then
        rm -f device/*/sepolicy/common/private/genfs_contexts
        (
            cd device/phh/treble
    if [[ $choice == *"y"* ]];then
            git clean -fdx
    fi
            bash generate.sh "$treble_generate"
        )
        bash "$(dirname "$0")/apply-patches.sh" patches
    else
        (
            cd device/phh/treble
            git clean -fdx
            bash generate.sh
        )
        repo manifest -r > release/"$rom_fp"/manifest.xml
        bash "$(dirname "$0")"/list-patches.sh
        cp patches.zip release/"$rom_fp"/patches.zip
    fi
}

function build_variant() {
    lunch "$1"
    make $extra_make_options BUILD_NUMBER="$rom_fp" installclean
    make $extra_make_options BUILD_NUMBER="$rom_fp" -j "$jobs" systemimage
    make $extra_make_options BUILD_NUMBER="$rom_fp" vndk-test-sepolicy
    cp "$OUT"/system.img release/"$rom_fp"/system-"$2".img
}

function jack_env() {
    RAM=$(free | awk '/^Mem:/{ printf("%0.f", $2/(1024^2))}') #calculating how much RAM (wow, such ram)
    if [[ "$RAM" -lt 16 ]];then #if we're poor guys with less than 16gb
	export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx"$((RAM -1))"G"
    fi
}

function clean_build() {
    make installclean
    rm -rf "$OUT"
}

parse_options "$@"
get_rom_type "$@"
get_variants "$@"

if [[ -z "$mainrepo" || ${#variant_codes[*]} -eq 0 ]]; then
    >&2 help
    exit 1
fi

# Use a python2 virtualenv if system python is python3
python=$(python -V | awk '{print $2}' | head -c2)
if [[ $python == "3." ]]; then
    if [ ! -d .venv ]; then
        virtualenv2 .venv
    fi
    . .venv/bin/activate
fi

init_release
if [[ $choice == *"y"* ]];then
init_main_repo
init_local_manifest
init_patches
sync_repo
fi
patch_things
fix_missings
jack_env

. build/envsetup.sh

for (( idx=0; idx < ${#variant_codes[*]}; idx++ )); do
    build_variant "${variant_codes[$idx]}" "${variant_names[$idx]}"
done

read -p "Do you want to clean? (y/N) " clean

if [[ $clean == *"y"* ]];then 
clean_build
fi
