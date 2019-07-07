#! /usr/bin/env python

import subprocess

def run(command):
    return str(subprocess.check_output(command, shell=True)).split("\\n")
