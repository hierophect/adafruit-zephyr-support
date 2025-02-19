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
uart:~$ spi conf
conf: wrong parameter count
conf - Configure SPI
       Usage: spi conf <device> <frequency> [<settings>]
       <settings> - any sequence of letters:
       o - SPI_MODE_CPOL
       h - SPI_MODE_CPHA
       l - SPI_TRANSFER_LSB
       T - SPI_FRAME_FORMAT_TI
       example: spi conf spi1 1000000 ol
Subcommands:
  spi@40080000
uart:~$ spi conf spi@40080000 1000000
uart:~$ spi transceive 0x53 0x50 0x49 0x20 0x57 0x6f 0x72 0x6b 0x73
TX:
00000000: 53 50 49 20 57 6f 72 6b  73                      |SPI Work s       |
RX:
00000000: 53 50 49 20 57 6f 72 6b  73                      |SPI Work s       |
uart:~$
```

For the example scan above:
1. I had an SHT41 (address 0x44) connected to my Feather RP2350. The scan
   implementation comes from
   [zephyr/drivers/i2c/i2c\_shell.c](https://github.com/zephyrproject-rtos/zephyr/blob/main/drivers/i2c/i2c_shell.c).
2. I had a 330 Ohm resistor from MOSI to MISO for SPI loopback. The SPI shell
   implementation comes from
   [zephyr/drivers/spi/spi\_shell.c](https://github.com/zephyrproject-rtos/zephyr/blob/main/drivers/spi/spi_shell.c).

SPI chip select is a bit mysterious. From checking with a Saleae, I'm not sure
if it's working and CS is being continuously asserted low, or if the pin is in
high impedance mode, or what. It might be the case that I'd need to have
multiple devices with multiple CS pins set up to see any change on the CS
lines. Not sure.


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


## Calculating Flash Partition Layout

To play nice with CircuitPython, this board definition needs to use a flash
partition layout that respects the existing CircuitPython bootloader, NVM,
and CIRCUITPY drive partitions. The idea is that, at some point, people will
be able to upgrade from a non-Zephyr CircuitPython build to a Zephyr-based
CircuitPython build using UF2. That process should preserve the old contents
of the CIRCUITPY drive.

Notes from CircuitPython source:

1. CIRCUITPY drive partition start address and is defined in
   [ports/raspberrypi/mpconfigport.h](https://github.com/adafruit/circuitpython/blob/457edc304a96c64596ae423ca9e3eebd3641fa6d/ports/raspberrypi/mpconfigport.h#L29)
   as:
   ```
   #define CIRCUITPY_CIRCUITPY_DRIVE_START_ADDR (CIRCUITPY_FIRMWARE_SIZE + CIRCUITPY_INTERNAL_NVM_SIZE)
   ```
2. CircuitPython firmware size is defined in [mpconfigport.h](https://github.com/adafruit/circuitpython/blob/457edc304a96c64596ae423ca9e3eebd3641fa6d/ports/raspberrypi/mpconfigport.h) as:
   ```
   #define CIRCUITPY_FIRMWARE_SIZE (1020 * 1024)
   ```
3. NVM size is defined (also in mpconfigport.h) as:
   ```
   #define CIRCUITPY_INTERNAL_NVM_SIZE  (4 * 1024)
   ```

Notes from the Raspberry Pi [RP2350 datasheet](https://datasheets.raspberrypi.com/rp2350/rp2350-datasheet.pdf):

1. Bootloader lives in chip's 32kB mask ROM (Ch 5 intro)
2. Flash sector size is 4kB (section 5.1.2.1)
3. Bootloader scans the first 4kB of flash looking for `IMAGE_DEF` or
   `PARTITION_TABLE` blocks to decide if it should do a "Flash Image Boot",
   "Flash Partition Boot", or "Partition-Table-in-Image Boot". See datasheet
   sections 5.1.12, 5.1.13, and 5.1.14.

Notes from the zephyr linker files and devicetree spec files:

1. From `boards/raspberrypi/rpi_pico2/rpi_pico2.dtsi`: `image_def` partition
   starts at `0x00000000` and is 256 bytes (`0x100`)
2. From `soc/raspberrypi/rpi_pico/rp2350/linker.ld`: flash is linked at
   ```
   MEMORY
   {
       IMAGE_DEF_FLASH (r) : ORIGIN = 0x10000000, LENGTH = 128
   }
   ```

Notes from Adafruit Feather RP2350 product page:

1. External flash chip size is 8MB


So, that tells us...

| Partition  | Start Address     | Size                   |
| ---------- | ----------------- | ---------------------- |
| Bootloader | N/A (mask ROM)    | N/A                    |
| IMAGE\_DEF | 0                 | 0x000100   (256B)      |
| Firmware   | 0x000100   (256B) | 0x0fef00 (1020kB-256B) |
| NVM        | 0x0ff000 (1020kB) | 0x001000    (4kB)      |
| CIRCUITPY  | 0x100000    (1MB) | 0x700000    (7MB)      |
