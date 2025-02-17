# Feather RP2350 Board Definition

This board definition for the Adafruit Feather RP2350 is derived from the
`zephyrproject-rtos/zephyr/boards/raspberrypi/rpi_pico2` board definition.
Most the changes have to do with pinctrl devicetree config because the board
pinouts are different.


## Build & Flash Zephyr Shell Sample

Programming with OpenOCD and the Raspberry Pi Debug Probe is convenient but
optional. If you prefer, you can use UF2 with the ROM bootloader.


### UF2 Bootloader Option

First build the shell with I2C, SPI, and UART serial support:
```
$ cd zephyr-workspace
$ ls
adafruit-zephyr-support  bootloader  modules  openocd  tools  zephyr
$ source .venv/bin/activate
(.venv) $ cd adafruit-zephyr-support
(.venv) $ west build -b feather_rp2350/rp2350a/m33 \
 ../zephyr/samples/subsys/shell/shell_module/      \
 -- -DBOARD_ROOT=$(pwd)                            \
 -DCONFIG_I2C_SHELL=y -DCONFIG_SPI_SHELL=y
```

Then copy `build/zephyr/zephyr.uf2` to the bootloader's RP2350 drive by
whatever method you prefer.


### OpenOCD + Raspberry Pi Debug Probe Option

If you want to use OpenOCD with the Raspberry Pi Debug Probe, you will need to
build a copy of the Raspberry Pi version of `openocd` because upstream
`openocd` does not support the RP2350 yet (as of mid February 2025). See the
"Getting OpenOCD to Work" section below for details on building `openocd`.

Build and flash the shell sample with I2C, SPI, and UART:
```
$ cd zephyr-workspace
$ ls
adafruit-zephyr-support  bootloader  modules  openocd  tools  zephyr
$ source .venv/bin/activate
(.venv) $ cd adafruit-zephyr-support
(.venv) $ west build -b feather_rp2350/rp2350a/m33 \
 ../zephyr/samples/subsys/shell/shell_module/      \
 -- -DOPENOCD=../openocd/build/bin/openocd         \
 -DBOARD_ROOT=$(pwd)                               \
 -DCONFIG_I2C_SHELL=y -DCONFIG_SPI_SHELL=y
```

Then flash with west:
```
(.venv) $ west flash
```


## Use Zephyr Shell with tio

Once you've flashed the shell firmware, you can try using the `i2c` and `spi`
commands in the Zephyr shell. When your serial monitor connects, you may need
to type Enter a couple times to get a shell prompt.

At the shell prompt, you can do stuff like:
```
(.venv) $ tio /dev/serial/by-id/usb-Raspberry_Pi_Debug_Probe*
...
uart:~$ demo board
feather_rp2350
uart:~$ version
Zephyr version 4.0.99
uart:~$ i2c
  scan         recover      read         read_byte    direct_read  write
  write_byte   speed
uart:~$ i2c scan i2c@40098000
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:             -- -- -- -- -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- 44 -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
1 devices found on i2c@40098000
uart:~$ spi
spi - SPI commands
Subcommands:
  conf        : Configure SPI
                Usage: spi conf <device> <frequency> [<settings>]
                <settings> - any sequence of letters:
                o - SPI_MODE_CPOL
                h - SPI_MODE_CPHA
                l - SPI_TRANSFER_LSB
                T - SPI_FRAME_FORMAT_TI
                example: spi conf spi1 1000000 ol
  cs          : Assign CS GPIO to SPI device
                Usage: spi cs <gpio-device> <pin> [<gpio flags>]example: spi
                conf gpio1 3 0x01
  transceive  : Transceive data to and from an SPI device
                Usage: spi transceive <TX byte 1> [<TX byte 2> ...]
uart:~$ spi conf spi0 10000000
device spi0 not found.
```

So far I2C works, but SPI is mysterious. Most of the zephyr samples and tests
related to SPI are tied to specific hardware configurations. I haven't been
able to get any of those working yet. Also, the RP2350 SPI driver's chip
select mechanism is mysterious (pinmux vs cs-gpio is unclear).

For the example scan above, I had an SHT41 (address 0x44) connected to my
Feather RP2350. The scan implementation comes from
[zephyr/drivers/i2c/i2c_shell.c](https://github.com/zephyrproject-rtos/zephyr/blob/main/drivers/i2c/i2c_shell.c).


## Getting OpenOCD to Work

Upstream OpenOCD doesn't support the RP2350 yet (as of Feb 2025). So, to
program the Feather RP2350 with the Raspberry Pi Debug Probe and OpenOCD, you
need to clone and build the Raspberry Pi
[fork of openocd](https://github.com/raspberrypi/openocd) and have west build
tell cmake where to find that openocd binary.

Example of cloning and building openocd into a Zephyr workspace directory
using a bash shell on Debian 12:
```
$ sudo apt install make libtool pkg-config \
    autoconf automake texinfo libusb-1.0-0-dev libhidapi-dev
$ cd zephyr-workspace
$ git clone https://github.com/raspberrypi/openocd.git
$ cd openocd
$ ./bootstrap
$ ./configure --prefix=$(pwd)/build
$ make
$ make install
```

Then, to make sure cmake finds the right binary, do something like:
```
$ cd zephyr-workspace
$ source .venv/bin/activate
(.venv) $ west build -b feather_rp2350/rp2350a/m33     \
    $APP_DIR/samples/whatever --                       \
    -DOPENOCD=$WORKSPACE_DIR/openocd/build/bin/openocd \
    -DBOARD_ROOT=$WORKSPACE_DIR/adafruit-zephyr-support/boards
```
