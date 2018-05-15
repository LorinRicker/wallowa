#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringGroupings.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 05/15/2018
#

class String

  # Separate groups of characters with a separator
  def groupsep( grp = 3, sep = ",", decpt = '.' )
    num = self.to_s.strip
    if num.include?(decpt)
      nums = num.split(decpt)
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
      thou = nums.join(decpt)
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
