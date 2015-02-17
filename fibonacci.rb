#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# fibonacci.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.4, 06/04/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'

# This recursive algorithm works in exponential time, with O(N**m)
# costs beginning to be noticeable on fast processors at ~ Fib(32):
def fibonacci_slow( n )
  return n if (0..1).include? n
  fibonacci_slow( n-2 ) + fibonacci_slow( n-1 )
end  # fibonacci

# But this memoized algorithm is simply linear -- it works by
# remembering all previous results for subsequent look-up,
# even though the actual algorithm remains recursive, trading
# (re)computation for memory...  Thanks to:
#  Gregory Brown, "Ruby Best Practices", "Memoization" pp. 138ff
#
# Initialize the series:
@fib_series = [ 0, 1 ]

def fibonacci_fast( n )
  @fib_series[n] ||= fibonacci_fast( n-2 ) + fibonacci_fast( n-1 )
end  # fibonacci_fast
alias :fib :fibonacci_fast
