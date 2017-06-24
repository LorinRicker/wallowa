#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

#       Chained_Iterators.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 07/04/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

def chained_iterator( arg = 'HAL' )
  chars = arg              .tap { |o| puts "original object: #{o.inspect}" }
         .each_char        .tap { |c| puts "each_char returns: #{c.inspect}" }
         .to_a             .tap { |a| puts "to_a returns: #{a.inspect}" }
         .map {|c| c.succ} .tap { |m| puts "map returns: #{m.inspect}" }
         .sort             .tap { |s| puts "sort returns: #{s.inspect}" }
end  # chained_iterator

# Main -- test drivers:
 if $0 == __FILE__ then
   chained_iterator
   puts ""
   chained_iterator "DEC"
 end
