#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# pgmheaderfixup.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.4, 10/15/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# newline = line.removeCommentGap --
# Removes excess leading space from after comment-mark,
# turning:  "#       Comment text"
#    into:  "# Comment text"
# Note that this approach does *not* honor relative-indentation
# of "structured" comments; all leading whitespace (following
# the comment mark) is reduced to one space (by default).
def removeCommentGap( indent = 1, commark = "#" )
  gap = indent + 1
  if self[0] == commark
    while self[gap] == " "
      self[gap] = ""
    end  # while
  end  # if
  self
end  # removeCommentGap

# newline = line.trimCommentGap( 3 ) --
# Removes excess leading space from after comment-mark,
# turning:  "#       Comment text"
#    into:  "#    Comment text" (for example, trimmed 3 spaces)
# Note that this approach *does* honor relative-indentation
# of "structured" comments; in general, relative indents
# can/will be preserved.
def trimCommentGap( size = 5, commark = "#" )
  i = size
  if self[0] == commark
    while self[gap] == " " && i <= size
      self[gap] = ""
      i += 1
    end  # while
  end  # if
  self
end  # trimCommentGap


# Main -- test drivers:
if $0 == __FILE__ then

end
