#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ls.rb
#
# Copyright © 2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# ls -- *nix-style directory listing.
# Note: The following ls command options (only) are implemented:
#       -a -A --almost-all
#       -l --long
#       -R --recursive

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.1 (06/30/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/WhichOS'

require 'DECC'

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

«.»

exit true
