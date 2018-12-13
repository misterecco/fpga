BUILD = ./build 
PRJ = abc
VFILES = abc.v div.v

$(PRJ): $(PRJ).bit

# Synteza (.v -> .ngc)
$(PRJ).ngc: $(VFILES) $(PRJ).xst $(PRJ).prj
	xst -ifn $(PRJ).xst
# Linkowanie (.ngc -> .ngd)
$(PRJ).ngd: $(PRJ).ucf $(PRJ).ngc
	ngdbuild $(PRJ) -uc $(PRJ).ucf
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
$(PRJ).ncd: $(PRJ).ngd
	map $(PRJ)
# Place and route (.ncd -> lepszy .ncd)
$(PRJ)_par.ncd: $(PRJ).ncd
	par -w $(PRJ).ncd $(PRJ)_par.ncd
# Generowanie finalnego bitstreamu (.ncd -> .bit)
$(PRJ).bit: $(PRJ)_par.ncd
	bitgen -w $(PRJ)_par.ncd -g StartupClk:JTAGClk
# Programowanie płytki
flash: $(PRJ).bit
	djtgcfg -d Basys2 prog -i 0 -f abc_par.bit

clean:
	rm -rf $(PRJ).{ngc,lso,srp} xst build _xmsgs
	rm -rf $(PRJ).{ngd,bld} netlist.lst xlnx_auto_0_xdb
	rm -rf $(PRJ).{ncd,pcf,map,mrp,ngm}
	rm -rf $(PRJ)_par*
	rm -rf $(PRJ).bit
	rm *.xrpt *.xml *.html *.log

