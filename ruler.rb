#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ruler.rb
#
# Copyright © 2012-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.1 (02/05/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

# Provides a quick way to "toss up" a horizontal rule for visually
# determining horizontal positions across a terminal display.
#
# An 80-column ruler looks like this (actual display would omit the leading '# '):
#
#     .    |    .    |    .    |    .    |    .    |    .    |    .    |    .    |
#          1         2         3         4         5         6         7         8
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890
#     .    |    .    |    .    |    .    |    .    |    .    |    .    |    .    |
#
# A ruler's display expands (or shrinks) to horizontally-fill the current terminal's
# width (number of columns).
#
# The top-left corner of the display is defined to be 1;1 (row;col or line;col).

require 'optparse'
require 'pp'
require_relative 'lib/ANSIseq'
require_relative 'lib/TermChar'
require_relative 'lib/Rule'

# ==========

options = { :atline     => 1,
            :style      => :default,
            :color      => :blue,
            :verbose    => false,
            :debug      => DBGLVL0,
            :about      => false
          }

# Parse the command line --
optparse = OptionParser.new { |opts|
  opts.on( "-l", "-@", "--atline=LINE", "--@line", Integer,
           "line-# to display ruler (1 = top-of-screen)" ) do |val|
    options[:atline] = val
  end  # -l -@ --atline --@line
  opts.on( "-s", "--style=STYLE", /default|both|before|after|none/i,
           "Style for hash-marks (both (d), before, after, none)" ) do |val|
  options[:style] = val || :default
  end  # -s --style
  opts.on( "-c", "--color=COLOR", /black|red|green|brown|blue|purple|cyan|yellow|white/i,
           "Ruler color (blue (d), black, red, green, brown, blue, purple, cyan, yellow, white" ) do |val|
  options[:color] = val.to_sym || :blue
  end  # -c --color
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] [BackupDir]" +
                "\n\n   The target BackupDir (directory) can be specified either as the command"   +
                "\n   argument or as the value of the option --backuptree.  If both are provided," +
                "\n   then the command argument is used.  The SourceDir is always specified as"    +
                "\n   the value of the --sourcetree option.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    options[:help] = true
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

pp options if options[:verbose]

# Create and show a RULER with the given style, color and at the line specified:
Rule.ruler( options[:style] ).color(options[:color]).atposition( row: options[:atline] )
