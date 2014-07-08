#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ArrayEnhancements.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 07/05/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

class Array

  def sort_caseblind( reverse = false )
    # Want a case-blind sort: all "a..." with all "A...", etc.
    self.sort do | a, b |
      reverse ? b.downcase <=> a.downcase : a.downcase <=> b.downcase
    end
  end  # sort_caseblind!

  def sort_caseblind!( reverse = false )
    # Want a case-blind sort: all "a..." with all "A...", etc.
    self.sort! do | a, b |
      reverse ? b.downcase <=> a.downcase : a.downcase <=> b.downcase
    end
  end  # sort_caseblind!

end  # class Array
