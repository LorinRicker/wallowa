#!/usr/bin/ruby1.9.1
# -*- encoding: utf-8 -*-

# programfilenames1.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 06/20/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'pquts'
require '~/projects/RubyDemos/ProgramFileNames2'

# Main -- test drivers:
if $0 == __FILE__ then
  pquts $0, "\n1.  PROGRAM_NAME ($0)"
  pquts __FILE__, "1.  __FILE__"
end
