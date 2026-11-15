#!/usr/bin/env bash
# Rebuild the pinned Apple OSS dependencies required by the B2L XNU target.
# The signed Apple KDK remains the only external/private build input.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xnu_path="${XNU_PATH:-$repo_root/xnu}"
deps_root="${B2L_DEPSROOT:?Set B2L_DEPSROOT to an isolated output directory}"
: "${KDKROOT:?Set KDKROOT to the merged KDK + KDK_SDK root}"

deps_src="$repo_root/out/dependencies"
deps_build="$repo_root/out/apple-deps"
mkdir -p "$deps_src" "$deps_build" "$deps_root"

fetch_pinned() {
  local name="$1" url="$2" commit="$3" dest="$deps_src/$1"
  rm -rf "$dest"
  git init -q "$dest"
  git -C "$dest" remote add origin "$url"
  git -C "$dest" fetch -q --depth 1 origin "$commit"
  git -C "$dest" checkout -q --detach FETCH_HEAD
  local actual
  actual="$(git -C "$dest" rev-parse HEAD)"
  [[ "$actual" == "$commit" ]] || { echo "Unexpected $name revision: $actual" >&2; exit 1; }
  printf '%s\n' "$dest"
}

availability_commit=149b1777f3e8c2133042d8e188f72e3adf6a7110
libdispatch_commit=701f4d1a24ae9c6863901bbbb22624b7d1b87321
availability_src="$(fetch_pinned AvailabilityVersions https://github.com/apple-oss-distributions/AvailabilityVersions.git "$availability_commit")"
libdispatch_src="$(fetch_pinned libdispatch https://github.com/apple-oss-distributions/libdispatch.git "$libdispatch_commit")"

echo "::group::Build pinned AvailabilityVersions"
make -C "$availability_src" install \
  SRCROOT="$availability_src" \
  OBJROOT="$deps_build/availability-obj" \
  SYMROOT="$deps_build/availability-sym" \
  DSTROOT="$deps_root"
availability="$deps_root/usr/local/libexec/availability"
test -x "$availability" || { echo "AvailabilityVersions did not install usr/local/libexec/availability" >&2; exit 1; }
install -m 0755 "$availability" "$deps_root/usr/local/libexec/availability.pl"
test -x "$deps_root/usr/local/libexec/availability.pl"
echo "::endgroup::"

echo "::group::Install headers from the pinned, prepared XNU tree"
[[ "$(git -C "$xnu_path" rev-parse HEAD)" == ac9718fb1af618d5ce8678d0dc6e8a58f252216f ]] || {
  echo "XNU source is not at the repository's pinned commit" >&2; exit 1;
}
make -C "$xnu_path" SDKROOT=macosx ARCH_CONFIGS="X86_64 ARM64" \
  OBJROOT="$deps_build/xnu-headers-obj" \
  SYMROOT="$deps_build/xnu-headers-sym" \
  DSTROOT="$deps_root" installhdrs
kernel_private="$deps_root/System/Library/Frameworks/Kernel.framework/PrivateHeaders"
kernel_public="$deps_root/System/Library/Frameworks/Kernel.framework/Headers"
test -d "$kernel_private" || { echo "XNU did not install Kernel.framework/PrivateHeaders" >&2; exit 1; }
test -d "$kernel_public" || { echo "XNU did not install Kernel.framework/Headers" >&2; exit 1; }
# XNU's MakeInc kernel search path is /usr/local/include/kernel. Populate it
# from the same build's actual exported private Kernel.framework headers.
mkdir -p "$deps_root/usr/local/include/kernel"
ditto "$kernel_private" "$deps_root/usr/local/include/kernel"
test -d "$deps_root/usr/local/include/os" || {
  echo "XNU did not export usr/local/include/os; refusing to substitute generic headers" >&2; exit 1;
}
echo "::endgroup::"

echo "::group::Build the pinned iPhoneOS ARM64 Firehose archive"
LIBDISPATCH_SOURCE="$libdispatch_src" scripts/build-firehose.sh
firehose="$deps_root/usr/local/lib/kernel/libfirehose_kernel.a"
test -s "$firehose" || { echo "libfirehose_kernel.a was not installed at the required path" >&2; exit 1; }
echo "::endgroup::"

echo "::group::Validate generated dependency contract"
test -x "$deps_root/usr/local/libexec/availability.pl"
test -d "$deps_root/usr/local/include/kernel"
test -d "$deps_root/usr/local/include/os"
test -d "$deps_root/usr/local/include/firehose" || {
  echo "Firehose headers were not exported to usr/local/include/firehose" >&2; exit 1;
}
test -s "$firehose"
echo "Generated B2L_DEPSROOT: $deps_root"
find "$deps_root/usr/local" -maxdepth 4 -type f | sort | head -n 80
echo "::endgroup::"
