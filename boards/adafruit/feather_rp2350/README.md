# Feather RP2350 Board Definition

This board definition for the Adafruit Feather RP2350 is derived from the
`zephyrproject-rtos/zephyr/boards/raspberrypi/rpi_pico2` board definition.
Most the changes have to do with pinctrl devicetree config because the board
pinouts are different.


## Sample Usage with Raspberry Pi Debug Probe

First, you need to build openocd with RP2350 support (see next section).

Then, something like this should work to build and run the Zephyr shell sample
with I2C support (paths might need tweaks depending on how you did west init):
```
$ cd zephyr-workspace
$ ls
adafruit-zephyr-support  bootloader  modules  openocd  tools  zephyr
$ source .venv/bin/activate
(.venv) $ cd adafruit-zephyr-support
(.venv) $ west build -b feather_rp2350/rp2350a/m33  \
    ../zephyr/samples/subsys/shell/shell_module/    \
    -- -DOPENOCD=../openocd/build/bin/openocd       \
    -DBOARD_ROOT=$(pwd)                             \
    -DCONFIG_I2C=y -DCONFIG_I2C_SHELL=y
(.venv) $ west flash
(.venv) $ screen -fn /dev/serial/by-id/*Pi_Debug* 115200
```

In screen, type Enter a couple times to get the Zephyr shell prompt. From
the prompt, you can do stuff like this:
```
uart:~$
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
uart:~$
```

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
