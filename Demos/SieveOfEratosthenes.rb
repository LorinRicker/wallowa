#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# dcl.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

# Compute prime numbers up to user-specified (or 100)
#   with the Sieve of Eratosthenes
max = ARGV[0] ? ARGV[0].to_i : 100

sieve = Array.new(max + 1, true)
sieve[0] = false
sieve[1] = false

(2...max).each do |i|
  if sieve[i]
    (2 * i).step(max, i) do |j|
      sieve[j] = false
    end
  end
end

sieve.each_with_index do |prime, number|
  puts number if prime
end
