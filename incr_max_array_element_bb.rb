#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# incr_max_array_element_bb.rb
#
# Copyright © 2015-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.1, 09/24/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'benchmark'
include Benchmark

TEST_REP = 20
LOOP_REP = 10000

bmbm( TEST_REP ) do | test |
  ids = []
  test.report( "     Next id: #to_i methos to handle NIL: " ) do
    LOOP_REP.times do | dummy |
      nextid = ids.max.to_i + 1
      ids << nextid
    end
  end
  ids = []
  test.report( "Next id: Conditional logic to handle NIL: " ) do
    LOOP_REP.times do | dummy |
      nextid = ( ids.max || 0 ) + 1
      ids << nextid
    end
  end
end
