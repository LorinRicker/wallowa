#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# factorial.rb
#
# Copyright (C) 2011-2012 Lorin Ricker <lorin@rickernet.us>
# Version: 0.5, 07/14/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'pp'

# This recursive algorithm works in exponential time:
def factorial_slow( n )
#  puts "n = #{n}"
  n <= 1 ? 1 : n * factorial_slow( n-1 )
end  # factorial_slow

# But this memoized algorithm is simply linear -- it works by
# remembering all previous results for subsequent look-up,
# even though the actual algorithm remains recursive, trading
# (re)computation for memory...  Thanks to:
#  Gregorg Brown, "Ruby Best Practices", "Memoization" pp. 138ff
#
# Initialize the series:
@fact_series = [ 1 ]

def factorial_fast( n )
  @fact_series[n] ||= n * factorial_fast( n-1 )
end  # factorial_fast
alias :fact :factorial_fast
alias :n!   :factorial_fast
