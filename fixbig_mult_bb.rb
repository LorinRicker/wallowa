#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# fixbig_mult_bb.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.1, 11/17/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'benchmark'
include Benchmark

TEST_REP = 6
A_BUNCH  = 1000000

res1, res2 = '', ''

bmbm( TEST_REP ) do | test |
  test.report( "Multiplication with Fixnums :" ) do
    A_BUNCH.times { res1 = 999 * 888 }
  end
  test.report( "Multiplication with Bignums :" ) do
    A_BUNCH.times { res2 = 9999999999999999999 * 8888888888888888888 }
  end
end
