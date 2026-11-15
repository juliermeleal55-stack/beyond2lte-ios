#!/usr/bin/env bash
# Build Apple's pinned libfirehose_kernel for the B2L iPhoneOS ARM64 kernel.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${B2L_DEPSROOT:?Set B2L_DEPSROOT to the generated Apple dependency root}"
: "${KDKROOT:?Set KDKROOT to the merged KDK + KDK_SDK root}"
libdispatch_src="${LIBDISPATCH_SOURCE:-$repo_root/out/dependencies/libdispatch}"
[[ -f "$libdispatch_src/libdispatch.xcodeproj/project.pbxproj" ]] || {
  echo "Pinned libdispatch Xcode project not found: $libdispatch_src" >&2; exit 1;
}
[[ -d "$B2L_DEPSROOT/System/Library/Frameworks/Kernel.framework/PrivateHeaders" ]] || {
  echo "Generated XNU private Kernel.framework headers are missing" >&2; exit 1;
}
build_root="${B2L_BUILD_ROOT:-$repo_root/out/apple-deps/firehose}"
mkdir -p "$build_root/obj" "$build_root/sym" "$B2L_DEPSROOT/usr/local/lib/kernel"

header_paths="$libdispatch_src $libdispatch_src/src $libdispatch_src/src/firehose $B2L_DEPSROOT/usr/local/include/kernel $B2L_DEPSROOT/usr/local/include/os $B2L_DEPSROOT/usr/local/include/firehose $B2L_DEPSROOT/System/Library/Frameworks/Kernel.framework/PrivateHeaders $B2L_DEPSROOT/System/Library/Frameworks/Kernel.framework/Headers $KDKROOT/System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders $KDKROOT/System/Library/Frameworks/Kernel.framework/Versions/A/Headers $KDKROOT/usr/local/include/os $KDKROOT/usr/local/include/firehose"

xcodebuild install \
  -project "$libdispatch_src/libdispatch.xcodeproj" \
  -target libfirehose_kernel \
  -configuration Release \
  -sdk iphoneos \
  ARCHS=arm64 VALID_ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  OBJROOT="$build_root/obj" \
  SYMROOT="$build_root/sym" \
  DSTROOT="$B2L_DEPSROOT" \
  CODE_SIGNING_ALLOWED=NO \
  OTHER_CFLAGS='$(inherited) -mcpu=generic -march=armv8-a+crypto' \
  HEADER_SEARCH_PATHS="$header_paths"

archive="$B2L_DEPSROOT/usr/local/lib/kernel/libfirehose_kernel.a"
test -s "$archive" || {
  echo "Xcode did not install the expected archive: $archive" >&2
  find "$B2L_DEPSROOT" -name '*firehose*.a' -print >&2
  exit 1
}
file "$archive"
lipo -info "$archive"
