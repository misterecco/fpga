#!/usr/bin/env python3

import argparse
import usb1
from adepttool.device import get_devices
import sys

parser = argparse.ArgumentParser(description='Super simple EPP communication with the FPGA on Basys 2.')
parser.add_argument('--device', type=int, help='Device index (Default: 0)', default=0)
parser.add_argument('--port', type=int, help='Port index (Default: 0)', default=0)
parser.add_argument('-p', nargs=2, metavar=("ADDR", "VAL"), help='Put VAL into ADDR. (eg. -p 0e 0x10) ')
parser.add_argument('-g', metavar="ADDR", help='Get value from ADDR. (eg. -g 0a)')

args = parser.parse_args()

with usb1.USBContext() as ctx:
    devs = get_devices(ctx)
    if args.device >= len(devs):
        if not devs:
            print('No devices found.')
        else:
            print('Invalid device index (max is {})'.format(len(devs)-1))
        sys.exit(1)
    dev = devs[args.device]
    dev.start()
    port = dev.depp_ports[args.port]
    port.enable()

    if args.g is not None:
        addr = int(args.g, 16)
        print("%x" % port.get_reg(addr, 1)[0])
    elif args.p is not None:
        addr, val = args.p
        addr, val = int(addr, 16), int(val, 16)
        port.put_reg(addr, [val])
    else:
        print('DEPP PORT {port.idx}: {port.caps:08x}'.format(port=port))

    port.disable()

