# GitHub Actions build

The workflow `.github/workflows/beyond2lte-build.yml` builds the pinned XNU kernel on an Apple Silicon macOS runner, builds the external beyond2lte UEFI firmware on Linux, then packages and verifies an Android v1 BOOT image.

## One-time repository setup

Add these GitHub Actions repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Required content |
|---|---|
| `B2L_KDK_ARCHIVE_URL` | HTTPS URL to a gzip tar archive containing the legally obtained, merged Apple Kernel Debug Kit 26.5 payload. Both `KDK.pkg` and `KDK_SDK.pkg` payloads must already be merged into the extracted tree. |
| `B2L_DEPS_ARCHIVE_URL` | HTTPS URL to a gzip tar archive whose root contains the prepared `B2L_DEPSROOT` tree. It must include `usr/local/libexec/availability.pl`, exported XNU/private firehose headers, and `usr/local/lib/kernel/libfirehose_kernel.a` built for iPhoneOS ARM64. |

Optional token secrets for private artifact hosting: `B2L_KDK_ARCHIVE_TOKEN` and `B2L_DEPS_ARCHIVE_TOKEN`.

The archive URLs must be directly downloadable by `curl`. The workflow does not bypass Apple Developer authentication or redistribute Apple's SDK/KDK. Do not commit SDKs, KDK packages, credentials, device backups, or personalized images to this repository.

## Run

1. Open **Actions** in this repository.
2. Select **beyond2lte XNU BOOT build**.
3. Select **Run workflow** on branch `github-actions-builder`.
4. Inspect the three jobs: `kernel`, `firmware`, and `package`.
5. Download `beyond2lte-ios-boot-image` only if all jobs succeed.

The kernel job checks for an Apple Silicon runner, Xcode 27.1, macOS SDK 27, and iPhoneOS SDK 26.5. It fails early if the runner image no longer provides the pinned toolchain. The KDK and dependency archives are external prerequisites; creating a workflow cannot manufacture those licensed/private inputs.

The firmware job checks out Mu-Silicium with recursive submodules, applies the external beyond2lte overlay, runs board memory-layout audits, builds the XNU EFI loader, and requires exactly one 4 MiB firmware FD.

The package job runs the repository's `package-boot.py` and its independent `--verify` path. The 64 MiB limit is an offline packaging ceiling, not a measured capacity for the phone's BOOT partition.

## Important limits

A successful workflow means the image passed source/build/container checks. It does not prove that S-Boot accepts it or that this specific phone boots it. The workflow does not connect to or flash a phone. Do not install the artifact until the actual device identity, BOOT partition capacity, backup, and image readback procedure have been checked separately.