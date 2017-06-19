#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# bignum.rb
#
# Copyright © 2016-2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.1 (06/19/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

DEFAULT_DCLSYMBOL = "BIGNUM_RESULT"
VMSONLY_BORDER    = "    " + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = "    " + '=' * ( VMSONLY_BORDER.length - 4 )
# -----

require 'optparse'
require 'pp'
require_relative 'lib/ppstrnum'
require_relative 'lib/TermChar'
require_relative 'lib/WhichOS'

# ==========

# === Main ===
options = { :format    => 'sep',
            :just      => 'right',
            :separator => ',',
            :indent    => 2,
            :os        => :linux,
            :dclsymbol => nil,
            :noop      => false,
            :verbose   => false,
            :debug     => DBGLVL0,
            :about     => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-f", "--format[=DISPLAY]", /SEP|WORD|BARE|ASC|DESC/i,
           "Format to display:",
           "  SEP: comma separated triads (default),",
           "  BARE: no separator,",
           "  WORD: number-names,",
           "  ASC:  number-names in ascending triads,",
           "  DESC: number-names in descending triads" ) do |val|
    options[:format] = val.downcase || "sep"
  end  # -f --format
  opts.on( "-i", "--indent[=INDENTATION]", Integer,
           "Display indentation width (default is 2 spaces)" ) do |val|
    options[:indent] = val.to_i.abs
  end  # -i --indent
  opts.on( "-j", "--just[=JUSTIFICATION]", /LEFT|RIGHT/i,
           "Format justification: right (default) or left" ) do |val|
    options[:just] = val.downcase || "right"
  end  # -j --just
  opts.on( "-s", "--separator[=SEPARATOR]", String,
           "Triads separator (default is ',' comma)" ) do |val|
    options[:separator] = val.to_i.abs
  end  # -s --separator
  opts.separator "\n#{VMSONLY_BORDER}"
  opts.on( "-r", "--variable[=VARNAME]", String,
           "DCL variable (symbol) name for expression result",
           " (default variable name is #{DEFAULT_DCLSYMBOL},",
           "  but ignored if not hosted on VMS (OpenVMS))" ) do |val|
    options[:dclsymbol] = ( val || DEFAULT_DCLSYMBOL ).upcase
  end  # -r --symbol  --variable
  opts.separator "#{VMSONLY_BORDEREND}\n\n"
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] \"EXPRESSION\"" +
                "\n\n    where \"EXPRESSION\" is a numeric expression to evaluate and display in" +
                "\n    the selected format.  Enclose the expression in double-quotes, e.g." +
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

# Strip commas from each arg:
ARGV.each_with_index { |a,i| ARGV[i] = a.tr( ',', '' ) }

args = ARGV.join( ' ' )
# Check that only numbers 0..9, arithmetical operators +, -, * and /,
# decimal, space and parentheses () are present in args:
pat = /[.0-9+\-*\/\ \(\)]+/
raise "Expression error, illegal characters" if args !~ pat

bignum = 0
cmd = "bignum = #{args}"
puts "\n  eval( '#{cmd}' )\n\n" if options[:verbose]

# This is, of course, a Bad Thing... to accept arbitrary input from
# the command line and then execute (eval) it directly.  Hence, the
# regex-pattern match above, to limit/filter the args to just things
# that "look like arithmetic expressions" --
#############
eval( cmd ) #  <-- Don't try this at home...
#############

case options[:format].to_sym
when :sep
    result = bignum.thousands
when :bare
    result = bignum
when :word
    result = bignum.numbernames
when :asc, :desc
    result = bignum.pp_numstack( options )
#when :desc
#    result = bignum.desc_numstack
end

case options[:os]
when :linux
  puts result
when :vms
  # tuck result into a DCL GLobal Symbol
  puts result
end  # case

exit true
