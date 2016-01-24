#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# binary.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: v0.1 - 12/31/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

# This is a recursive binary expansion of any integer value into its
# corresponding "string of bits" representation.
#
# This algorithm is discussed thoroughly by Mark Jason Dominus in his
# excellent book "High Order Perl", pp. 1~3 (Elsevier/Morgan Kaufmann
# Publishers, 2008, ISBN: 1-55860-701-3; out-of-print).

# Because this method is declared in the Numeric class, it can be invoked
# on Integer, Fixnum and Bignum values.  It has no problems producing the
# binary string expansions for:
#    (2**64).binary
#    (10**50 + 7).binary
# etc... Try it.
# If invoked on a Float, it truncates the fractional part and returns
# the binary string for the integer part: 3.14159.binary => "11"

class Numeric

  def binary              # 6.binary => "110", 255.binary => "11111111", etc.
    n = self.to_i
    return '0' if n == 0  # 1. By definition
    return '1' if n == 1  #    (ditto)
    k = ( n / 2 ).to_i    # 2. Compute k & b so that n == 2k + b,
    b = n % 2             #    and b = 0 or 1 (even or odd remainder)
    e = k.binary          # 3. recurse on k, resulting in its binary expansion
    e << b.to_s           # 4. Final result: string concatenation of e + b
  end  # binary

end  # class
