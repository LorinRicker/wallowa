#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# termchar.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.4 (11/08/2015)"
  AUTHOR = "Lorin Ricker, Elbert County, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/TermChar'

options = { :characters => false,
            :lines      => false,
            :geometry   => false,
            :winch      => false,
            :verbose    => false,
            :debug      => DBGLVL0,
            :about      => false
          }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-c", "--characters", "--width",
           "Display terminal width in characters" ) do |val|
    options[:characters] = true
  end  # -c --characters --width
  opts.on( "-l", "--lines", "--length",
           "Display terminal length in lines" ) do |val|
    options[:lines] = true
  end  # -l --lines --length
  opts.on( "-g", "--geometry",   # --geometry=80x24, WxL
           "Display terminal geometry as WxL" ) do |val|
    options[:geometry] = true
  end  # -g --geometry
  opts.on( "-w", "--window-change", "--winch",
           "Report each window change event" ) do |val|
    options[:winch] = true
  end  # -w --window-change --winch
  # --- Verbose option ---
  opts.on( "-v", "--verbose", "--log", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
  # --- Debug option ---
  opts.on( "-d", "--debug", "=DebugLevel", Integer,
           "Show debug information (levels: 1, 2 or 3)",
           "  1 - enables basic debugging information",
           "  2 - enables advanced debugging information",
           "  3 - enables (starts) pry-byebug debugger" ) do |val|
    options[:debug] = val.to_i
  end  # -d --debug
  # --- About option ---
  opts.on_tail( "-a", "--about", "Display program info" ) do |val|
    $stdout.puts "#{PROGID}"
    $stdout.puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] Display terminal characteristics\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

case
when options[:geometry]
  s = options[:verbose] ? "%#{PROGNAME}-i-WxL, terminal geometry is " : ""
  puts "#{s}#{TermChar.terminal_width}x#{TermChar.terminal_height}"
when options[:characters]
  s = options[:verbose] ? "%#{PROGNAME}-i-width, terminal width is " : ""
  puts "#{s}#{TermChar.terminal_width} characters"
when options[:lines]
  s = options[:verbose] ? "%#{PROGNAME}-i-length, terminal length is " : ""
  puts "#{s}#{TermChar.terminal_height} lines"
when options[:winch]
  begin
    loop do # forever, until user enters Ctrl/C...
      TermChar.every_window_change_event do | wce |
        s = options[:verbose] ? "%#{PROGNAME}-i-WxL, terminal geometry is " : ""
        puts "#{s}#{TermChar.terminal_width}x#{TermChar.terminal_height}"
      end
    end
  rescue SystemExit
    exit true
  end
else
  TermChar.terminal_dimensions( true )
end
