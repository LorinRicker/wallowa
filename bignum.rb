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
  PROGID = "#{PROGNAME} v2.3 (06/20/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

DEFAULT_VARNAME   = "BIGNUM_RESULT"
VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )
DCLSCOPE_LOCAL    = 1
DCLSCOPE_GLOBAL   = 2
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
            :varname   => nil,
            :dclscope  => DCLSCOPE_LOCAL,
            :noop      => false,
            :verbose   => false,
            :debug     => DBGLVL0,
            :about     => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-f", "--format[=DISPLAY]", /SEP|WORD|BARE|ASC|DESC/i,
           "Format to display:",
           "  SEP: comma separated groups (default),",
           "  BARE: no separator,",
           "  WORD: number-names,",
           "  ASC:  number-names in ascending groups,",
           "  DESC: number-names in descending groups" ) do |val|
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
  opts.on( "-g", "--separator[=SEPARATOR]", String,
           "Group separator (default is ',' comma)" ) do |val|
    options[:separator] = val.to_i.abs
  end  # -s --separator

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

# Strip commas from each arg:
ARGV.each_with_index { |a,i| ARGV[i] = a.tr( ',', '' ) }

ARGV.each_with_index { | arg, idx |
  # Check that only numbers 0..9, arithmetical operators +, -, * and /,
  # decimal, space and parentheses () are present in arg:
  pat = /[.0-9+\-*\/\ \(\)]+/
  raise "Expression error, illegal characters" if arg !~ pat

  bignum = 0
  cmd = "bignum = #{arg}"
  puts "\n  eval( '#{cmd}' )" if options[:verbose]

  # This is, of course, a Bad Thing... to accept arbitrary input from
  # the command line and then execute (eval) it directly.  Hence, the
  # regex-pattern match above, to limit/filter the arg to just things
  # that "look like arithmetic expressions" --
  #############
  eval( cmd ) #  <-- Don't try this at home...
  #############

  case options[:format].to_sym
  when :sep
      result = bignum.thousands
  when :bare
      result = bignum.to_s
  when :word
      result = bignum.numbernames
  when :asc, :desc
      result = bignum.pp_numstack( options )
  #when :desc
  #    result = bignum.desc_numstack
  end

  case options[:os]
  when :linux, :unix, :windows
    if options[:varname]
      # Tuck result into a shell environment variable -- Note that, for non-VMS,
      # this is *useless* (mostly), as the environment variable is created in
      # the (sub)process which is running this Ruby script, thus the parent process
      # (which com-line-ran the script) never sees the env-variable!
      envvar = options[:varname] + "#{idx+1}"
      ENV[envvar] = result
      STDOUT.puts "%#{PROGNAME}-i-createenv, created shell environment variable #{envvar}, value '#{result}'" if options[:verbose]
    else
      STDOUT.puts result
    end  # if
  when :vms
    if options[:varname]
      # Tuck result into a DCL Variable/Symbol --
      require 'RTL'
      dclsym = options[:varname] + "#{idx+1}"
      RTL::set_symbol( dclsym, result, options[:dclscope] )
      STDOUT.puts "%#{PROGNAME}-i-createsym, created DCL variable/symbol #{dclsym}, value '#{result}'" if options[:verbose]
    else
      STDOUT.puts result
    end  # if
  end  # case

}  # ARGV.each_with_index

exit true
