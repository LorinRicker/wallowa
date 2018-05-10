#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringIsIn.rb
#
# Copyright © 2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 05/09/2018
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Monkey-patch String with a simple method

# Used by lib/AppCmdCompletions.rb, but generally useful too...

class String

  # isIn? returns true/false if a string (self) is found
  # in an array of words (ary) -- Everything is downcased
  # for case-insensitive testing...
  def isIn?( ary )
    words = Array.new
    ary.each { |w| words << w.downcase }
    words.find_index( self.downcase )
  end # isIn?

end  # class String
