##
# Copyright (c) 2011 - 2022, ARM Limited. All rights reserved.
# Copyright (c) 2014, Linaro Limited. All rights reserved.
# Copyright (c) 2015 - 2020, Intel Corporation. All rights reserved.
# Copyright (c) 2018, Bingxing Wang. All rights reserved.
# Copyright (c) Microsoft Corporation.
#
# SPDX-License-Identifier: BSD-2-Clause-Patent
##

[Defines]
  USE_PHYSICAL_TIMER                         = 1
  HAS_CNTFRQ_EL0_EMPTY_ERRATA                = 0

!include SamsungPkg/SamsungPkg.dsc.inc

[BuildOptions]
  *_*_AARCH64_CC_FLAGS = -march=armv8.2-a+crypto+rcpc

[PcdsFixedAtBuild]
  gEfiMdeModulePkgTokenSpaceGuid.PcdAcpiDefaultOemTableId|0x2030323839453553
  gEfiMdeModulePkgTokenSpaceGuid.PcdAcpiDefaultOemRevision|0x9820

  # Exynos 9820 GPIO and SPEEDY controller addresses from Mu-Silicium.
  gSamsungPkgTokenSpaceGuid.PcdGpioCtrlAddr|{ 0x00, 0x00, 0x43, 0x10, 0x00, 0x00, 0x83, 0x10, 0x00, 0x00, 0x03, 0x13, 0x00, 0x00, 0xC4, 0x13, 0x00, 0x00, 0x58, 0x15, 0x00, 0x00, 0x85, 0x15, 0x00, 0x00, 0xC3, 0x15, 0x00, 0x00, 0xC6, 0x18 }
  gSamsungPkgTokenSpaceGuid.PcdSpeedyBusAddr|{ 0x00, 0x00, 0x97, 0x15, 0x00, 0x00, 0x98, 0x15 }

  gSamsungPkgTokenSpaceGuid.PcdHasSecurePgtbl|TRUE
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosProcessorModel|"Exynos (TM) 9820 @ 2.73 GHz"
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosProcessorPartNumber|"S5E9820"

[LibraryClasses]
  # Board-specific UFS PHY/UniPro initialization.
  PlatformUfsLib|S5E9820Pkg/Library/PlatformUfsLib/PlatformUfsLib.inf

  # Current Mu-Silicium library names and implementations.
  PlatformSecLib|S5E9820Pkg/Library/PlatformSecLib/PlatformSecLib.inf
  ResetSystemLib|S5E9820Pkg/Library/ResetSystemLib/ResetSystemLib.inf
  GpioBankLib|S5E9820Pkg/Library/GpioBankLib/GpioBankLib.inf
  HsI2cLib|S5E9820Pkg/Library/HsI2cLib/HsI2cLib.inf
  PmicLib|S5E9820Pkg/Library/PmicLib/PmicLib.inf
  UsiLib|S5E9820Pkg/Library/UsiLib/UsiLib.inf
