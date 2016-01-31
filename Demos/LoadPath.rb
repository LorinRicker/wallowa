#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# LoadPath.rb
#
# Copyright © 2011-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 01/30/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require '~/projects/ruby/lib/StringEnhancements'
require '~/projects/ruby/lib/pquts'

# Main -- test drivers:
if $0 == __FILE__ then
  pquts ENV["PATH"], 'ENV["PATH"]'
  pquts $LOAD_PATH, "$LOAD_PATH ($:, $-I)"
  pquts $LOADED_FEATURES, '$LOADED_FEATURES ($")'
end
