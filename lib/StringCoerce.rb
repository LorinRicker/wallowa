#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringCoerce.rb
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.2, 04/14/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# General Numeric coercement for class String --
# from 'Ruby Programming 1.9', Dave Thomas, p. 607:

#  Coerce is both an instance method of Numeric and part of a type conversion
#  protocol.  When a number is asked to perform an operation and it is passed
#  a parameter of a class different from its own, it must first coerce both
#  itself and that parameter into a common class os that the operation makes
#  sense.  For example, in the expression 1 + 2.5, the Fixnum +1+ must be
#  converted to a Float to make it compatible with +2.5+.  This conversion is
#  performed by Coerce.  For all numeric objects, coerce is straightforward:
#  if +numeric+ is the same type as +num+, returns an array containing
#  +numeric+ and +num+.  Otherwise, returns an array with both +numeric+
#  and +num+ represented as Float objects.
#
#    1.coerce(2.5)  # =>  [2.5, 1.0]
#    1.2.coerce(3)  # =>  [3.0, 1.2]
#    1.coerce(2)    # =>  [2, 1]
#
#  If a numeric object is asked to operate on a non-numeric, it tries to
#  invoke coerce on that other object.  For example, if you write this:
#
#    1 + "2"
#
#  Ruby will effectively execute the code as follows:
#
#    n1, n2 = "2".coerce(1)
#    n2 + n1
#
#  In the more general case, this won't work, because most non-numerics
#  don't define a coerce method.  However, you can use this (if you feel
#  so inclined) to implement part of Perl's automatic conversion of strings
#  to numbers in expressions."

class String

  def coerce( other )
    case other
    when Integer
      begin
        return other, Integer( self )
      rescue
        return Float( other ), Float( self )
      end
    when Float
      return other, Float( self )
    else
      super
    end  # case
  end  # coerce

end  # class String
