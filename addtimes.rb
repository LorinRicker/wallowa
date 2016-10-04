#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# addtimes.rb
#
# Copyright © 2016 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.1 (10/01/2016)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/TimeInterval'

# ==========

# === Main ===
options = { :operator => "add",
            :prompt   => false,
            :noop     => false,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-o", "--operator=OP",
           /add|subtract|plus|minus/ ) do |val|
    options[:operator] = val.to_sym
  end  # -o --operator=OP
  opts.on( "-p", "--prompt", "Prompt mode" ) do |val|
    options[:prompt] = true
  end  # -p --prompt
  opts.separator ""
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
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
  opts.banner = "  Adds (or subtracts) time intervals or durations." +
                "\n\n  Usage: #{PROGNAME} [options] tdur1 [tdur2...]" +
                "\n\n    where tdurN is a time duration or interval\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    # $stdout.puts "«+»Additional Text«+»"
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

# accumlates seconds, to be displayed as interval "d hh:mm:ss"
accint = TimeInterval.new

if ARGV[0]
  # Add all given args on command-line, even if prompt-mode is requested...
  ARGV.each do | arg |
    accint.accumulate( arg )
  end
end
if options[:prompt]
  # ...Prompt user for values, show running-tape of accumulated/calc'd time
  more_data = true
  while more_data
    begin
      # display current interval as prompt> -- get user's input
      accint.accumulate( str )
      promptstr = accint.to_s
    rescue # user pressed Ctrl/D or Ctrl/Z end-of-data-input
      more_data = false
    end
  end  # while
end

puts "\nAccumulated interval/duration: #{ accint }\n\n"

exit true
