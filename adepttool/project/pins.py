# This file is a general .ucf for Basys2 rev C board
# To use it in a project:
# - remove or comment the lines corresponding to unused pins
# - rename the used signals according to the project

import logging


class Pins:
    def __init__(self):
        self.log = logging.getLogger(name='Pins')
        loc = {}
        extra = {}
        
        #=== CLOCKS
        loc['mclk'] = ["B8"] 
        extra['mclk'] = {"CLOCK_DEDICATED_ROUTE": "FALSE"}

        loc['uclk'] = ["M6"]
        extra['uclk'] = {"CLOCK_DEDICATED_ROUTE": "FALSE"}

        #=== SWITCHES
        loc['sw'] = ["P11", "L3", "K3", "B4", "G3", "F3", "E2", "N3"]

        #=== BUTTONS
        loc['btn'] = ["G12", "C11", "M4", "A7"]

        #=== LEDS
        loc['Led'] = ["M5", "M11", "P7", "P6", "N5", "N4", "P4", "G1"]

        #=== 7-segment display
        loc['seg'] = (["M12", "L13", "P12", "N11", "N14", "H12", "L14"])[::-1]
        loc['an'] = ["F12", "J12", "M13", "K14"]
        loc['dp'] = ["N13"]

        #=== EPP ext pins
        loc['EppAstb'] = ["F2"]
        loc['EppDstb'] = ["F1"]
        loc['EppWR'] = ["C2"]
        loc['EppWait'] = ["D2"]
        loc['EppDB'] = ["N2", "M2", "M1", "L1", "L2", "H2", "H1", "H3"]

        #=== PS2
        loc['PS2C'] = ['B1']
        loc['PS2D'] = ['C3']
        extra['PS2C'] = {'DRIVE': 2, 'PULLUP': None}
        extra['PS2D'] = {'DRIVE': 2, 'PULLUP': None}

        #=== VGA
        loc['HSYNC'] = ['J14']
        loc['VSYNC'] = ['K13']
        loc['OutRed'] = ['C14', 'D13', 'F13']
        loc['OutGreen'] = ['F14', 'G13', 'G14']
        loc['OutBlue'] = ['H13', 'J13']
        extra['HSYNC'] = {'DRIVE': 2, 'PULLUP': None}
        extra['VSYNC'] = {'DRIVE': 2, 'PULLUP': None} 
        extra['OutRed'] = {'DRIVE': 2, 'PULLUP': None}
        extra['OutGreen'] = {'DRIVE': 2, 'PULLUP': None}
        extra['OutBlue'] = {'DRIVE': 2, 'PULLUP': None}


        self.extra = extra
        self.loc = loc

    def get_ucf(self, ios):

        def get_extras(extras, name):
            l = []
            if name in extras:
                for k, v in extras[name].items():
                    if v is None:
                        _s = k
                    else:
                        _s = '%s = %s' % (k, v)
                    l.append(_s)
            return " | ".join(l) if l else None

        self.log.info("Generating constraint file...")

        ucf_content = ""
        for n, r in ios:
            if n not in self.loc:
                self.log.error("`%s` external pin not found! Use --pins to see available external pins." % n)
                exit(1)

            s = ""
            extra_opts = get_extras(self.extra, n)
            if r is None:
                l = self.loc[n][0]
                s += 'NET "%s" LOC = "%s";\n' % (n, l)
                if extra_opts is not None:
                    s += 'NET "%s" ' % n + extra_opts + ";\n"
            else:
                a, b = r
                for idx, l in enumerate(self.loc[n][a:b+1]):
                    s += 'NET "%s<%d>" LOC = "%s";\n' % (n, idx, l)
                    if extra_opts is not None:
                        s += 'NET "%s<%d>" ' % (n, idx) + extra_opts + ";\n"
            self.log.info('Wire `%s` entries: \n' % n + s)
            ucf_content += s
        return ucf_content

    def print_all(self):
        l = [(k,len(v)) for k, v in self.loc.items()]
        print("{:^12s} {:^6s}".format("NET NAME", "WIDTH"))
        for k, w in l:
            print("{:>12s} {:^6d}".format(k, w))


