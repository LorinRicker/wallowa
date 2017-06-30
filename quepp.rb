#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# quepp.rb
#
# Copyright © 2016 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# quepp -- VMS Queue Pretty-Printer -- untangles the chaos which is
#          output "report" of the SHOW QUEUE /ALL /FULL command and
#          reorganizes that into a passably readable, compacted and
#          condensed format.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.2 (06/30/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}.yaml.rc" )

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/FileEnhancements'  # includes AppConfig class
require_relative 'lib/WhichOS'

# ==========

# === Main ===
options = { :«+»     => «+»,
            :«+»     => «+»,
            :noop    => false,
            :update  => false,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

options.merge!( AppConfig.configuration_yaml( CONFIGFILE, options ) )

optparse = OptionParser.new { |opts|
  opts.on( "-«+»", "--«+»",  # "=«+»", String,
           "«+»" ) do |val|
    options[:«+»] = «+»
  end  # -«+» --«+»
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] «+»ARG«+»" +
                "\n\n   where «+»\n\n"
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

# f1 = ARGV[0] || ""  # a completely empty args will be nil here, ensure "" instead
# f2 = ARGV[1] || ""

# ...(optional) other command-line processing goes here...

case WhichOS.identify_os
when :vms
  showque_rawreport = %x{ SHOW QUEUE /ALL /FULL }
when :linux, :windows, :mac
  showque_rawreport = '../TestData/VMSCLUSTER_SHOW_QUEUE.LIS_SAMPLE'
end

# now process/reformate that raw-report into something palatable:

exit true
