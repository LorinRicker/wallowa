#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# datecalc.rb
#
# Copyright © 2012-2015 Lorin Ricker <lorin@rickernet.us>
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.5 (02/16/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'pp'
require_relative 'lib/DateCalc'
require_relative 'lib/ANSIseq'

# === Main ===
options = { :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-a", "--after", "=N", Integer, "N".underline + " days after " + "date".underline + " is " + "<DATE>".bold ) do |val|
    options[:after] = val
  end  # -A
  opts.on( "-b", "--before", "=N", Integer, "N".underline + " days before " + "date".underline + " is " + "<DATE>".bold ) do |val|
    options[:before] = val
  end  # -B
  opts.on( "-t", "-w", "--between", "=DATE", "N days".bold + " between " + "date".underline + " and " + "date".underline ) do |val|
    options[:between] = val
  end  # -b
  opts.on( "-u", "--until", "=DATE", "N days".bold + " between " + "today".underline + " and " + "date".underline ) do |val|
    options[:until] = val
  end  # -u
#  opts.on( "-«·»", "--«·»", "Description-«·»" ) do |val|
#    options[:«·»] = «·»
#  end  # -«·»
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
  opts.banner = "\n  Usage: #{PROGNAME} options [date1 [date2]]\n\n"
  opts.on_tail( "-h", "-?", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    exit true  # status:0
  end  # -h
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

if !ARGV[0]
  ARGV << DateCalc.thisday( "today" ).to_s  # push the default if empty
else
  ARGV[0] = DateCalc.thisday( ARGV[0] ).to_s
end  # if !ARGV[0]
pp ARGV if options[:verbose]

# ARGV[0] (n_days) days after options[:after] (date) is...
DateCalc.days_after( options[:after], ARGV[0], true ) if options[:after]

# ARGV[0] (n_days) days before options[:before] (date) is...
DateCalc.days_before( options[:before], ARGV[0], true ) if options[:before]

# The number of days between ARGV[0] and options[:between] (dates) is...
DateCalc.days_between( ARGV[0], options[:between], true ) if options[:between]

# from "today" until options[:until] (date) is ??? days...
DateCalc.days_until( options[:until], true ) if options[:until]

# exit
