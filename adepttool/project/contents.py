
MAKEFILE = """

BUILD=out
TOP={top:}
TAR=$(BUILD)/$(TOP)_par.bit

all: synth 

FILES={deps:}

prog: $(TAR)
	basys2_prog $(TAR)

synth: $(BUILD) $(FILES)
	cd $(BUILD) && xst -ifn ../$(TOP).xst && ngdbuild $(TOP) -uc ../$(TOP).ucf && map $(TOP) && par -w $(TOP).ncd $(TOP)_par.ncd && bitgen -w $(TOP)_par.ncd -g StartupClk:JTAGCLK

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)


.PHONY: clean synth

"""

XST_CMD = "run -ifn ../{prj:} -p xc3s100e-4-cp132 -top {top:} -ofn {top:}"

