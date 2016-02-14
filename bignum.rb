#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# bignum.rb
#
# Copyright © 2016 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.0 (02/13/2016)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/ppstrnum'

# ==========

# === Main ===
options = { :format  => "sep",
            :noop    => false,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-f", "--format[=DISPLAY]", /SEP|WORD|BARE|ASC|DESC/i,
           "Format to display (SEP: comma separated triads,",
           "  BARE: no separator,",
           "  WORD: number-names,",
           "  ASC:  number-names in ascending triads,",
           "  DESC: number-names in descending triads)" ) do |val|
    options[:format] = val.downcase || "sep"
  end  # -f --format
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] EXPRESSION" +
                "\n\n    where EXPRESSION is a numeric expression to" +
                "\n    valuate and display in the selected format\n\n"
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

args = ARGV.join( ' ' )
bignum = 0
cmd = "bignum = #{args}"
puts "cmd: #{cmd}" if options[:verbose]
eval( cmd )

case options[:format].to_sym
when :sep
    result = bignum.thousands
when :bare
    result = bignum
when :word
    result = bignum.numbernames
when :asc
    result = bignum.numbernames
                   .split( ',' )
                   .reverse { |s| trim( s ) }
                   .join( ",\n")
when :desc
    result = bignum.numbernames
                   .split( ',' ) { |s| trim( s) }
                   .join( ",\n")
end

puts result

exit true
