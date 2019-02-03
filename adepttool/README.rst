adepttool
=======================

A set of tools to program the FPGA on Basys 2 boards.

Installation
----
Run::

    ./install.sh


Programmer
----
Usage: install Python 3 and libusb1, make sure you have the access rights
to the USB device (use the attached udev rule if you must), then run::

    basys2_prog file.bit


Project builder
----
Creates handy `Makefile` for code synth and chip programming.
Usage::

    basys2_prj [-vvv]

Flow:

1. Create project dir ``X``.
2. Create main file ``X.v`` with top module named ``X`` inside.
3. Write other modules.
4. Run ``basys2_prj`` and generate builder.
5. ``make``
6. ``make prog``

EEP
----
Simple communication with Basys2 board via EPP. [If you implemented such module, of course.]

Get register::

    basys2_epp -g ADDR

Put register::

    basys2_epp -p ADDR VAL

``ADDR`` and ``VAL`` should be hexstring, eg. ``ff``, ``0xa1``.

List devices
----
Usage::

    basys2_list
    
