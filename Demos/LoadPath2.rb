#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# LoadPath2.rb
#
# Copyright © 2011-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 01/30/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# see:
# www.skorks.com/2009/08/digging-into-a-ruby-installation-require-vs-load/

require 'pp'
#~ Ruby 1.9.x: Use rbconfig.rb instead of obsolete config.rb
#~ require 'config'
require 'rbconfig'

puts "$LOAD_PATH ($:)..."
puts $:

#~ LoadPath2.rb:26: Use RbConfig instead of obsolete and deprecated Config
## pp RbConfig::CONFIG
