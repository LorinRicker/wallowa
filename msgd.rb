#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# msgd.rb
#
# Copyright © 2016-2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# VMS (OpenVMS) has a CHECKSUM command, but its best message digest
# algorithm is (currently) MD5.  Cannot do SHA*, etc.
#
# But wait -- with VMS Ruby, we've got more!  Why not implement the
# advanced message digest algorithms with Ruby for VMS?

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.0 (06/25/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

require 'optparse'
require 'pp'
require_relative 'lib/WhichOS'
## require_relative 'lib/TermChar'

# ==========


# === Main ===
options = { :math      => nil,
            :noop      => false,
            :verbose   => false,
            :debug     => DBGLVL0,
            :about     => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-x", "--math[=EXACT]", String, /EXACT|NORMAL|INEXACT/i,
           "Display exact or normal (default) math results" ) do |val|
    options[:math] = true if ( val || "exact" ).upcase[0] == "E"
  end  # -x --math

  opts.separator ""
  opts.on( "-r", "--variable[=VARNAME]", String,
           "Variable (symbol) name for expression result;",
           "  default variable name is #{DEFAULT_VARNAME}, which",
           "  is always suffixed with the index-number for",
           "  that argument position, e.g., #{DEFAULT_VARNAME}1,",
           "  #{DEFAULT_VARNAME}2,... -rr becomes R1, R2, R3,..." ) do |val|
    options[:varname] = ( val || DEFAULT_VARNAME ).upcase
  end  # -r --variable

  opts.separator "\n#{VMSONLY_BORDER}"
  opts.on( "-s", "--scope[=DCLSCOPE]", /GLOBAL|LOCAL/i,
           "DCL variable scope (default LOCAL, or GLOBAL)" ) do |val|
    options[:dclscope] = ( val || "LOCAL" ).upcase[0] == "L" ?
                           DCLSCOPE_LOCAL : DCLSCOPE_GLOBAL
  end  # -x --scope
  opts.separator "\n    Options here are ignored if not VMS (OpenVMS)\n#{VMSONLY_BORDEREND}\n\n"

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
    require_relative 'lib/AboutProgram'
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] \"EXPRESSION1\" [ \"EXPRESSION2\" ]..." +
                "\n\n    where each \"EXPRESSION\" is a numeric expression to evaluate and display" +
                "\n    in the selected format.  Enclose each expression in double-quotes, e.g." +
                "\n    \"2**64\" to ensure that special characters such as asterisk/splats are" +
                "\n    not misinterpreted.\n\n"
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

options[:os] = WhichOS.identify_os

pp options if options[:debug] >= DBGLVL2

#####################################################
# If included, math results are "exact":            #
#   36/16 => 9/4                                    #
# Not included generates "normal" math results:     #
#   36/16 => 2                                      #
require 'mathn' if options[:math] # Unified numbers #
#####################################################


exit true
