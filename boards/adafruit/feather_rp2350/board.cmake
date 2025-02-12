# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Copyright 2025 Sam Blenny

# CAUTION: For this to work, you will need to clone and build the Raspberry
# Pi fork of openocd and use a suitable cmake config for that binary. At the
# time I'm writing this (Feb 11, 2025), upstream openocd does not yet support
# the RP2350. To get openocd, see https://github.com/raspberrypi/openocd

board_runner_args(openocd --cmd-pre-init "adapter driver cmsis-dap")
board_runner_args(openocd --cmd-pre-init "adapter speed 5000")
board_runner_args(openocd --cmd-pre-init "source [find target/rp2350.cfg]")
board_runner_args(uf2 "--board-id=RP2350")
include(${ZEPHYR_BASE}/boards/common/openocd.board.cmake)
include(${ZEPHYR_BASE}/boards/common/uf2.board.cmake)
