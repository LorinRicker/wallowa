# Thousands.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 06/08/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
#

# Note: A thousands method is defined for both Numeric and String
#       Classes, as it's feasible and expected to see invocations
#       of it for both 1234567890.thousands and "123456".thousands
#       instances (for both strings and numeric values).  Hence,
#       the Numeric.thousands is simply a wrapper, with a to_s
#       conversion, around String.thousands.

class String

# Separate groups of characters with a separator
  def groupsep( grp = 3, sep = ",", dec = '.' )
    num  = self.to_s.strip
    pat  = Regexp.compile( '\#{dec}(\d*)' )
    if num.include?(dec)
      nums = num.split( /\.(\d*)/ )
      nums.delete_if { |n| n == "" }
      num = nums[0]
    end
    thou = []
    while num != ""
      ln  = num.length < grp ? num.length : grp
      tpl = num[-ln,grp]
      num[-ln,grp] = ""
      thou << tpl
    end  # while
    thou = thou.reverse.join(sep)
    if nums
      nums[0] = thou
      thou = nums.join(dec)
    end
    return thou
  end  # groupsep

  # Separate a string (usually digits) into thousands --
  # e.g. "23456789" => "23,456,789"
  # (See Note above, and Numeric.thousands below...)
  def thousands( sep = "," )
    self.groupsep( 3, sep )
  end  # thousands

end  # class String


class Numeric

  # This wrapper hands-off a Numeric (Integer, Bignum, etc. ) to
  # the same-named String method, handling the to_s conversion as a
  # convenience, thus avoiding calls like: 1234567890.to_s.thousands
  def thousands( sep = "," )
    self.to_s.thousands( sep )
  end  # thousands

end  # class Numeric
