#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# deltree.rb
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

# deltree performs a 'sane rmdir' or 'sane rm -fR', including a --drawtree
# to let the user confirm the directory (sub)tree to delete.
#
# Includes a --noop, and a --confirm mode, as well as --verbose (etc.)
