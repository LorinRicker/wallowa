#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# what.rb
#
# Copyright © 2017 Avdi Grimm <support@rubytapas.com>, Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Attribution:  This "code fragment" comes directly and unaltered  (well, almost)
# by cut-&-paste (well, almost) from Avdi Grimm's RubyTapas education series
# (https://rubytapas.com), Episode 471 entitled 'Which' --
#    https://www.rubytapas.com/2017/03/20/episode-471-which/
#
# This code snippet is just too good, deserves to be used in a real-live tool!
# You, dear reader, are strongly encouraged to read Avdi's lucid code design
# walkthru in the RubyTapas episode above...
#

require 'pp'

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.0 (03/20/2017)"
  AUTHOR = "Avdi Grimm, adapted by Lorin Ricker, USA"

begin  # poor-man's help parsing:
  puts "usage:  what program_name [...]"
  exit false
end if ARGV.length == 0 || ARGV[0] == '-?' || ARGV[0].include?( '-h' )

suffixes = [""]
suffixes.concat( ENV.fetch( "PathExt", "" ).split (File::PATH_SEPARATOR ) )

ARGV.each do | command |
  dirs = ENV["PATH"]
    .split( File::PATH_SEPARATOR )
    .product( suffixes )
    .map{ | dir, suffix | File.join( dir, command ) + suffix }
    .find{ | p | File.executable?( p ) }
  pp dirs
end  # ARGV.each

exit true
