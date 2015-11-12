#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Sheldon.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 06/04/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

def sheldon( who )
  who ||= "Penny"
  knock = "knock! " * 3
  3.times { puts "#{knock}#{who}!..." }
end  # sheldon

  # Alternative:
  #
  #   3.times { puts "#{ 3.times { print "knock! " } }#{who}!..." }
  #
  #   -- But the above outputs this line three times:
  #   knock! knock! knock! 3Penny!...
  #   -- Where does the "3" come from?

# -- main --

sheldon(nil)

# Alternative calls -- what does each print?
#  sheldon( "Leonard" )
#  sheldon

sheldon ARGV[0] if ARGV[0]
