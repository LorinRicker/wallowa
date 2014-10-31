#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# «·».rb
#
# Copyright © 2012-2014 Lorin Ricker <lorin@rickernet.us>
# Version 0.1, «·»/«·»/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'optparse'
require_relative 'lib/FileEnhancements'  # includes AppConfig class


PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.«·» («·»/«·»/2012)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}.yaml.rc" )

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2
DBGLVL3 = 3

# ==========

def config_save( opt )
  # opt is a local copy of options, so we can patch a few
  # values without disrupting the original/global hash --
  opt[:about]     = false
  opt[:debug]     = DBGLVL0
  opt[:«+»]       = «+»
  opt[:noop]      = false
  opt[:sudo]      = ""
  opt[:update]    = false
  opt[:verbose]   = false
  AppConfig.configuration_yaml( CONFIGFILE, opt, true )  # force the save/update
end  # config_save

# === Main ===
options = {
            :«+» => «+»,
            :about      => false,
            :debug      => DBGLVL0,
            :noop       => false,
            :sudo       => "",
            :update     => false,
            :verbose    => false
          }

options.merge!( AppConfig.configuration_yaml( CONFIGFILE, options ) )

optparse = OptionParser.new { |opts|
  opts.on( "-«+»", "--«+»",  # "=«+»", String,
           "«+»" ) do |val|
    options[:«+»] = «+»
  end  # -«+» --«+»
  opts.separator ""
  opts.separator "    The options below are always saved in the configuration file"
  opts.separator "    in their 'off' or 'default' state:"
  opts.on( "-S", "--sudo",
           "Run this backup/restore with sudo" ) do |val|
    options[:sudo] = "sudo"
  end  # -S --sudo
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
  opts.on( "-u", "--update", "--save",
           "Update (save) the configuration file; a configuration",
           "file is automatically created if it doesn't exist:",
           "#{CONFIGFILE}" ) do |val|
    options[:update] = true
  end  # -u --update
  opts.on( "-v", "--verbose", "--log", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
  opts.on( "-d", "--debug", "=DebugLevel", Integer,
           "Show debug information (levels: 1, 2 or 3)" ) do |val|
    options[:debug] = val.to_i
  end  # -d --debug
  opts.on_tail( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "  Usage: #{PROGNAME} [options] [BackupDir]"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

# f1 = ARGV[0] || ""  # a completely empty args will be nil here, ensure "" instead
# f2 = ARGV[1] || ""

# ...(optional) other command-line processing goes here...

# Update the config-file, at user's request:
config_save( options ) if options[:update]

# Application processing goes here...

exit true
