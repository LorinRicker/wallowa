#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# eva.rb
#
# Copyright © 2016-2018 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# 1. Originally conceived: As a means to evaluate numeric (arithmetic)
#    expressions involving Bignums (a deprecated class with v2.4+,
#    all's Integer and Numeric now).
# 2. Recognized: How to make this work for Math trig/transcendental
#    methods too.
# 3. Ephiphany: The core Ruby eval method works generically for String
#    methods, and possibly other things.

PROGNAME = File.basename( $0, '.rb' )
  PROGID = "#{PROGNAME} v3.11 (05/15/2018)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

DEFAULT_VARNAME   = "EVA"
VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )
DCLSCOPE_LOCAL    = 1
DCLSCOPE_GLOBAL   = 2
# -----

require 'optparse'
require 'pp'
require_relative 'lib/WhichOS'
require_relative 'lib/GetPrompted'
## require_relative 'lib/TermChar'

# Expose methods which may be used by User on command-line:
require_relative 'lib/ppstrnum'
require_relative 'lib/Combinatorics'

# ==========

def display_methods( v, verbo )
  # Set-up for terminal dimensions, especially varying width:
  require_relative 'lib/TermChar'
  scrwidth = TermChar.terminal_width

  instmethods = Array.new
  cmd = "instmethods = #{v}.instance_methods.sort"
  STDOUT.puts ">>> cmd: \"#{cmd}\"" if verbo
  eval( cmd )
  # Find the max-length method name
  maxlen = 0
  instmethods.each { | el | sz = el.to_s.size; maxlen = sz > maxlen ? sz : maxlen }
  # maxlen now is max method-name length...
  line = ""
  instmethods.each do | imethod |
    imstr = imethod.to_s
    flen = maxlen + 1 - imstr.size
    impadded = "#{imstr}#{' '*flen}"
    if ( line != "" )
      line << + impadded
    else
      line = impadded
    end
    if ( line.length >= scrwidth - maxlen )
      STDOUT.puts line
      line = ""
    end
  end  # instmethods.each
end  # display_methods

# =========

def math_patterns
  # Ruby's Math module defines 26 trig and transcendental functions:
  pat0 = Regexp.new(
         / \b(                    # word-boundary, then Capture Group 1
               a?(cos|sin|tan)h?  # cos, sin, tan, acos, asin, atan,
                                  # cosh, sinh, tanh, acosh, asinh, atanh
             | atan2              # atan2
             | (cb|sq)rt          # cbrt (cube-root), sqrt (square-root)
             | erfc?              # erf, erfc (error-function and its complement)
             | (fr|ld)?exp        # exp, frexp, ldexp
             | l?gamma            # gamman, lgamma
             | hypot              # hypot (hypotenuse of a right-triangle with sides a,b)
             | log(2|10)?         # log (natural), log2, log10
             ) \s*\(              #   => "sin(..." or "sin (..." or "sin    (..."
         /x )
  pat1 = Regexp.new( /(\bE\b | \bPI\b )/x )    # "e" or "pi"
  # Custom Combinatorics class defines 5 combination, permutation, factorial
  # and Fibonacci functions:
  pat2 = Regexp.new(             # for Combinatorics class
         / \b(                    # word-boundary, then Capture Group 1
               (fib|fibonacci)    # Fibonacci series
             | (factorial|n!)     # Factorial series, n!
             | (k_)?permutations  # permutations
             | combinations       # combinations
             ) \s*\(              #   => "fib(..." or "fib (..." or "fib    (..."
         /x )
  return [ pat0, pat1, pat2 ]
end  # math_patterns

def sub_patterns( arg )
  # If an expression contains one or more patterned-functions,
  # prefix these appropriately --
  arg = arg.gsub( MPs[0], 'Math.\1(' )  # use single-quotes around 'Math.\1(', etc!!
  arg = arg.gsub( MPs[1], 'Math::\1'  )
  arg = arg.gsub( MPs[2], 'Combinatorics.\1('  )
  return arg
end # sub_patterns

def evaluate( arg, debug )
  tmp = 0
  cmd = "tmp = #{arg}"
  # There is, of course, a "Limited Liability" with eval'ing
  # any input provided by the user... but actually not a lot
  # more than if the user had written this script him/herself --
  #############
  eval( cmd ) #  <- creates object/variable 'tmp'
  #############
  if debug
    STDOUT.puts "\n  eval( '#{cmd}' )"
    STDOUT.puts "  raw: #{tmp.inspect}\n\n"
  end
  return tmp
end # evaluate

def format_result( tmp, options )
  fmt = ! tmp.kind_of?( Numeric ) ? "nonNumeric" : options[:format]
  case fmt.to_sym
  when :sep
      result = tmp.thousands
  when :bare
      result = tmp.to_s
  when :word
      result = tmp.numbernames
  when :asc, :desc
      result = tmp.pp_numstack( options )
  when :nonNumeric
    result = tmp.inspect  # pp-type format
  #when :desc
  #    result = tmp.desc_numstack
  end
  return result
end # format_result

def output( result, options, idx )
  if options[:varname]
    case options[:os]
    when :linux, :unix, :windows
      create_Env_variable( result, options, idx )
    when :vms
      create_DCL_symbol( result, options, idx )
    end  # case
  end  # if
  STDOUT.puts result
end # output

def create_Env_variable( result, options, idx )
  # Tuck result into a shell environment variable -- Note that, for non-VMS,
  # this is *useless* (mostly), as the environment variable is created in
  # the (sub)process which is running this Ruby script, thus the parent process
  # (which com-line-ran the script) never sees the env-variable!
  # So, the following is just a "demo" --
  envvar = options[:varname] + "#{idx+1}"
  ENV[envvar] = result
  STDOUT.puts "%#{PROGNAME}-i-createenv, created shell environment variable #{envvar}='#{result}'" if options[:verbose]
end # create_Env_variable

def create_DCL_symbol( result, options, idx )
  # Tuck result into a DCL Variable/Symbol --
  require 'RTL'
  dclsym = options[:varname].upcase + "#{idx+1}"
  RTL::set_symbol( dclsym, result, options[:dclscope] )
  aop = ( options[:dclscope] == DCLSCOPE_LOCAL ) ? '=' : '=='
  STDOUT.puts "%#{PROGNAME}-i-createsym, created DCL variable/symbol #{dclsym} #{aop} '#{result}'" if options[:verbose]
end # create_DCL_symbol

# === Main ===
options = { :math      => nil,
            :format    => 'sep',
            :just      => 'right',
            :separator => ',',
            :methods   => nil,
            :indent    => 2,
            :prompt   => false,
            :os        => :linux,
            :varname   => nil,
            :dclscope  => DCLSCOPE_LOCAL,
            :noop      => false,
            :verbose   => false,
            :debug     => DBGLVL0,
            :about     => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-p", "--prompt", "Prompt mode; can be used/combined with the",
                             "arguments (timeints) on the command-line" ) do |val|
    options[:prompt] = true
  end  # -p --prompt
  opts.on( "-x", "--math[=EXACT]", String, /EXACT|NORMAL|INEXACT/i,
           "Display exact or normal (default) math results" ) do |val|
    options[:math] = true if ( val || "exact" ).upcase[0] == "E"
  end  # -x --math
  opts.on( "-f", "--format[=DISPLAY]", /SEP.*|WORDS?|BARE|ASC.*|DESC.*/i,
           "Format to display:",
           "  SEP:  comma separated groups (default),",
           "  BARE: no separator,",
           "  WORD: number-names,",
           "  ASC:  number-names in ascending groups,",
           "  DESC: number-names in descending groups" ) do |val|
    format = { :S => "sep", :W => "word", :B => "bare",
               :A => "asc", :D => "desc" }.fetch( val[0].upcase.to_sym )
    options[:format] = ( format || "sep" )
  end  # -f --format
  opts.on( "-i", "--indent[=INDENTATION]", Integer,
           "Display indentation width (default is 2 spaces)" ) do |val|
    options[:indent] = val.to_i.abs
  end  # -i --indent
  opts.on( "-j", "--just[=JUSTIFICATION]", /LEFT|RIGHT/i,
           "Format justification: right (default) or left" ) do |val|
    options[:just] = ( val || "right" ).downcase
  end  # -j --just
  opts.on( "-g", "--separator[=SEPARATOR]", String,
           "Group separator (default is ',' comma)" ) do |val|
    options[:separator] = val.to_i.abs
  end  # -s --separator
  opts.on( "-m", "--methods=RubyClassName", /Numeric|Integer|Fixnum|Bignum|Float/i,
           "Display methods for a Ruby Numeric class" ) do |val|
    options[:methods] = val.to_s.capitalize!
    if val
      display_methods( val, false )
      exit 1
    end
  end  # -m --methods

  opts.separator ""
  opts.on( "-r", "--variable[=VARNAME]", String,
           "Variable (DCL symbol) name for expression result;",
           "  default variable name is #{DEFAULT_VARNAME}, which",
           "  is always suffixed with the index-number for",
           "  that argument position, e.g., #{DEFAULT_VARNAME}1, #{DEFAULT_VARNAME}2,...",
           "  -rr and --variable=r become R1, R2, R3,...",
           "  A separate variable is created for each",
           "  expression on the command line." ) do |val|
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
                "\n    not intercepted and misinterpreted by the command-line interpreter itself.\n\n"
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

MPs = math_patterns  # regexs to test for special forms...

idx = 0
if ARGV[0]
  # Evaluate all given args on command-line, even if prompt-mode is requested...
  ARGV.each do | arg |
    # arg = sub_patterns( arg )
    # evatmp = evaluate( arg, options[:verbose] )
    # result = format( evatmp, options[:format] )
    # ...or, functionally:
    result = format_result( evaluate( sub_patterns( arg ), options[:verbose] ), options )
    output( result, options, idx )
    idx += 1
  end  # ARGV.each_with_index
end  # if ARGV[0]
if options[:prompt] || ARGV.empty?
  pstr = PROGNAME.lowercase
  # ...Prompt user for values, show running-tape of accumulated/calc'd time
  # display current interval as prompt> -- get user's input, no default answer:
  while iarg = getprompted( pstr, "", false )
    break if iarg == ""
    result = format_result( evaluate( sub_patterns( iarg ), options[:verbose] ), options )
    output( result, options, idx )
    idx += 1
  end  # while
end  # if options[:prompt]

exit true
