#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# factorial.rb
#
# Copyright (C) 2011-2014 Lorin Ricker <lorin@rickernet.us>
# Version: 0.5, 06/04/2014
# Version: 0.6, 06/24/2014, adds Permutation and Combination
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
