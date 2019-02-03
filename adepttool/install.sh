#!/bin/bash

set -x

pip3 install --user -r requirements.txt

ln -s ${PWD}/basys2_prj.py ~/.local/bin/basys2_prj
ln -s ${PWD}/basys2_prog.py ~/.local/bin/basys2_prog
ln -s ${PWD}/basys2_epp.py ~/.local/bin/basys2_epp
ln -s ${PWD}/list.py ~/.local/bin/basys2_list

echo 'Remember about exporting ${HOME}/.local/bin in PATH'
