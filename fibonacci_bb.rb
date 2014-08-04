#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# fibonacci_bb.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.1, 07/25/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'benchmark'
include Benchmark

require_relative './fibonacci'

# This is a practical upper-limit for recursive method fibonacci_slow:
FS_LIMIT = 33

TEST_REP = 12

bmbm( TEST_REP ) do | test |
  test.report( "Recursive fibonacci_slow(#{FS_LIMIT}):" ) do
    fibonacci_slow( FS_LIMIT )
  end
  test.report( " Memoized fibonacci_fast(#{FS_LIMIT}):" ) do
    fibonacci_fast( FS_LIMIT )
  end
end
