#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# SumOfDigits.rb
#
# Copyright © 2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 01/18/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# String method sumof performs an (iterative) "sum of digits" in a string of
# digits, a primitive or trivial "digest," "signature," "checksum" or "hash,"
# otherwise known as an "integer number", returning that sum both as an integer
# value and as a string value, with intermediate-length results.
# Output is an actual Ruby hash containing the number of "rounds" needed to
# reduce the original digit string to a resultant string of desired length
# (default is 1), together with the final and intermediate resultant integer
# and string values.

# Examples -- irb session:
# alikot$ irb
# >> fl 'lib/SumOfDigits.rb'
# fl - file load: lib/SumOfDigits.rb
# => nil
# >> x = "1234567890"
# => "1234567890"
# >> x.sumof( 1 )
# => {"rounds"=>2, "sum2digit"=>45, "str2digit"=>"45", "sum1digit"=>9, "str1digit"=>"9"}
#
# Using a very BigNum:
# >> x = "1234567890123456789012345678901234567890123456789012345678901234567890
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890"
# >> x.sumof( 3 )
# => {"rounds"=>2, "sum4digit"=>1755, "str4digit"=>"1755", "sum2digit"=>18, "str2digit"=>"18"}
# >> x.sumof( 2 )
# => {"rounds"=>2, "sum4digit"=>1755, "str4digit"=>"1755", "sum2digit"=>18, "str2digit"=>"18"}
# >> x.sumof( 1 )
# => {"rounds"=>3, "sum4digit"=>1755, "str4digit"=>"1755",
#                  "sum2digit"=>18, "str2digit"=>"18",
#                   sum1digit"=>9, "str1digit"=>"9"}

module SumOfDigits

  def sumof( len = nil )
    len ||= 1
    ds = self.to_s
    round = 0
    result = { "rounds" => 0 }
    result["sum1digit"] = self
    result["str1digit"] = ds
    while ds.length > len
      round += 1
      sum = 0
      ds.split('').each { | d | sum += d.to_i }
      ds = sum.to_s
      result[ "sum#{ds.length}digit" ] = sum
      result[ "str#{ds.length}digit" ] = sum.to_s
    end  # while
    result[ "rounds" ] = round
    return result
  end  # sumof

end  # module SumOfDigits

# -----

class Numeric
  include SumOfDigits
end
class String
  include SumOfDigits
end
