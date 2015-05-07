#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# purgekernel.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

PROGNAME = File.basename( DCLNAME ).upcase   # not "$0" here!...
  PROGID = "#{PROGNAME} v0.1 (05/07/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

# -----

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

# purgekernel supports the automated (user-driven) removal of old Linux kernel
# packages, using a command shell to execute 'apt-get purge linux-*' for both
# kernel images and kernel headers ...
# See "$dlb/Linux/HowTos/HowTo - Remove old Linux kernel packages.txt"
