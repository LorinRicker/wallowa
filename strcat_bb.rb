#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# strcat_bb.rb
#
# Copyright © 2014-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.1, 11/17/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'benchmark'
include Benchmark

TEST_REP = 2
A_BUNCH  = 100000

str1, str2 = '', ''

bmbm( TEST_REP ) do | test |
  test.report( "String concatenation with += :" ) do
    A_BUNCH.times { str1 += 'A' }
  end
  test.report( "String concatenation with << :" ) do
    A_BUNCH.times { str2 << 'B' }
  end
end
