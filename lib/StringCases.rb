#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringCases.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 05/15/2018
#

class String

  # Return boolean indicating if *all* alpha-characters in word
  # (or filename) are of the specified regex-case:
  def isallXcase?( rex )
    s = self.gsub( /[\W\d.,;:!?-]/, "" )
    s.split( "" ).all? { |c| c =~ rex }
  end  # isallXcase?

  # Return boolean indicating if *all* alpha-characters in word
  # (or filename) are lower-case:
  def isalldowncase?
    isallXcase?( /[a-z]/ )
  end  # isalldowncase?

  # Return boolean indicating if *all* alpha-characters in word
  # (or filename) are UPPER-CASE:
  def isallUPCASE?
    isallXcase?( /[A-Z]/ )
  end  # isallUPCASE?

  # Return boolean indicating if the alpha-characters in word
  # (or filename) are Mixed-Case (that is, not all lower-case
  # and not all UPPER-CASE):
  def isMixedCase?
    ! isallXcase?( /[a-z]/ ) and ! isallXcase?( /[A-Z]/ )
  end  # isMixedCase?

  # -----

  # Title case means to capitalize each word in string,
  # incidentally doing a string compress at the same time
  def titlecase
    capwords = []
    words = self.split
    words.each { |w| capwords << w.capitalize }
    return capwords.join( " " )
  end  # titlecase

end  # class String
