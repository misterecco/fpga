import os
import glob
import logging
import re

from .pins import Pins
from .contents import MAKEFILE, XST_CMD


class Project:

    def __init__(self, root_dir):
        self.log = logging.getLogger(name='Builder')

        self.root_dir = root_dir
        self.log.info("Root dir: {:s}".format(root_dir))

        self.top_module = os.path.basename(root_dir)
        self.log.info("Top module: {:s}".format(self.top_module))

        self.files = glob.glob(root_dir + '/*.v')
        self.log.info("Verilog files found: ")
        for fn in self.files:
            self.log.info(" - " + fn)

    def _ext_io(self):
        with open(self.top_module + '.v', 'r') as f:
            content = f.read()
        res = re.match(".*module (?P<name>\w+)\s*\((?P<args>[\[\]\s\w_,:]+)\);.*", content, re.M | re.S).groupdict()
        if self.top_module != res['name']:
            self.log.error("Wrong top module name!")
            exit()

        self.log.info('Found external IOs in `%s`:' % self.top_module)
        ios = []
        for arg in res['args'].split(','):
            res = re.match("(?P<T>input|output|inout)\s+(wire)?\s*\[(?P<a>.+):(?P<b>.+)\]\s*(?P<name>\w+)", arg.strip())
            if res is not None:
                d = res.groupdict()
                a, b = int(d['a']), int(d['b'])
                x, y = min(a,b), max(a, b)
                ios += [(d['name'], (x, y))]
                self.log.info(' - {T:} [{a:}:{b:}] {name:}'.format(**d))
            else:
                d = re.match("(?P<T>input|output|inout)\s+(wire)?\s*(?P<name>\w+)", arg.strip()).groupdict()
                ios += [(d['name'], None)]
                self.log.info(' - {T:} {name:}'.format(**d))
        return ios


    def generate_files(self):
        ext_ios = self._ext_io()

        # Generate UCF constraints file
        with open(self.top_module + ".ucf", "w") as f:
            ucf_str = Pins().get_ucf(ext_ios)
            f.write(ucf_str)

        # Generate *.xst file
        with open(self.top_module + ".xst", "w") as f:
            f.write(XST_CMD.format(prj=self.top_module + ".prj", top=self.top_module))

        # Generate *.prj file
        with open(self.top_module + ".prj", "w") as f:
                for fpath in self.files:
                    fn = os.path.basename(fpath)
                    f.write('verilog work %s\n' % fn)

        deps = [os.path.basename(fpath) for fpath in self.files]
        deps = " ".join(deps)
        with open("Makefile", "w") as f:
            f.write(MAKEFILE.format(top=self.top_module, deps=deps))

