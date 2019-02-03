#!/usr/bin/env python3

from project import Pins, Project
import os
import logging
from argparse import ArgumentParser


if __name__ == '__main__':
    parser = ArgumentParser(description='Basys2 project builder builder')
    parser.add_argument('-v', action='count', default=0)
    parser.add_argument('--pins', action="store_true", help='List available pins');
    args = parser.parse_args()
    
    if args.v < 1:
        lvl = logging.ERROR
    elif args.v < 2:
        lvl = logging.WARN
    else:
        lvl = logging.INFO
    logging.basicConfig(level=lvl)

    if args.pins:
        pins = Pins()
        pins.print_all()
    else:
        project = Project(root_dir=os.getcwd())
        project.generate_files()

