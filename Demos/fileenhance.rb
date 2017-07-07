#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# fileenhance.rb
#
# Copyright © 2011-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.5, 01/24/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative 'lib/StringEnhancements'
require_relative 'lib/FileEnhancements'
require_relative 'lib/pquts'
require 'pp'

# Main -- test drivers:
def ftdriver( f, fdef = "" )
  puts quts( f, "\nFile" ) + quts( fdef, "  Default" )
  fileh = File.parse( f, fdef )
  pp fileh
  pquts( ( File.join fileh[:dir], fileh[:base] ), "Reconstituted" )
end  # ftdriver

if $0 == __FILE__ then
  #~ ftdriver( "/home/lorin/projects/ruby/TesterRooney/TestFile.txt" )
  #~ ftdriver( "~/projects/ruby/TesterRooney/TestFile.txt" )
  #~ ftdriver( "TestFile.txt" )
  #~ ftdriver( "TesterRooney/TestFile.txt" )
  ftdriver( "~/.bashrc" )
  ftdriver( "./TesterRooney/TestFile.txt" )

  # No syntactical distinction between ".txt" as a bare extension
  # and ".txt" as a hidden file, so must supply "*.txt" for the
  # default filespec-part:
  ftdriver( "TestFile", "./TesterRooney/*.txt" )
  # But this way for a true hidden file ".bashrc":
  ftdriver( ".bashrc", "~" )

  # Propagate
  ftdriver( "", "~/TestFile.txt" )
  ftdriver( "TestFile", "~/*.txt" )
  ftdriver( "TestFile.txt", "~" )
end
