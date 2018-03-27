#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# mklnsToMyDesktop.rb
#
# Copyright © 2018 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Create a fully-specified pathname-link to a document,
# saving the symbolic link to ~/Desktop/

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v01 (03/26/2018)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'pwned'

# work-in-progress
