#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# factorial.rb
#
# Copyright (C) 2011-2015 Lorin Ricker <lorin@rickernet.us>
# Version: 0.5, 06/04/2014
# Version: 0.6, 06/24/2014, adds Permutation and Combination
# Version: 0.8, 12/21/2014, adds "Main -- test driver" test-case
#                           and tests for 52! and 120!
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'pp'

# This recursive algorithm works in quadratic time:
def factorial_slow( n )
#  puts "n = #{n}"
  n <= 1 ? 1 : n * factorial_slow( n-1 )
end  # factorial_slow

# But this memoized algorithm is simply linear -- it works by
# remembering all previous results for subsequent look-up,
# even though the actual algorithm remains recursive, trading
# (re)computation for memory...  Thanks to:
#  Gregory Brown, "Ruby Best Practices", "Memoization" pp. 138ff
#
# Initialize the series:
@factorial_series = [ 1 ]

def factorial_fast( n )
  @factorial_series[n] ||= n * factorial_fast( n-1 )
end  # factorial_fast

alias :fact :factorial_fast
alias :n!   :factorial_fast

# How many arrangements of n things taken k at a time? (order matters)
def permutation( n, k )
  n!(n) / n!(n-k)
end  # permutation

# How many selections of n things taken k at a time? (order is irrelevant)
def combination( n, k )
  permutation(n,k) / n!(k)
end  # combination

alias :perm :permutation
alias :comb :combination

# Main -- test driver:
if $0 == __FILE__ then
  # The following calculated values for 120! (a 201-digit value) is an
  #   independent evaluation from https://en.wikipedia.org/wiki/OCaml;
  #   the value for 52! (a 68-digit value), the number of distinct shuffles
  #   of 52-cards is from en.wikipedia.org/wiki/Orders_of_magnitude_(numbers)
  # If these print 'true', then we've got a pretty good cross-check...
  puts "120! calculation passed" if n!(120).to_s ==
    "6689502913449127057588118054090372586752746333138029810295671352301633557244962989366874165271984981308157637893214090552534408589408121859898481114389650005964960521256960000000000000000000000000000"
  puts " 52! calculation passed" if n!(52) ==
     80658175170943878571660636856403766975289505440883277824000000000000
end
