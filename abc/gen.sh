# Synteza (.v -> .ngc)
xst -ifn abc.xst
# Linkowanie (.ngc -> .ngd)
ngdbuild abc -uc abc.ucf
# Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)
map abc
# Place and route (.ncd -> lepszy .ncd)
par -w abc.ncd abc_par.ncd
# Generowanie finalnego bitstreamu (.ncd -> .bit)
bitgen -w abc_par.ncd -g StartupClk:JTAGClk