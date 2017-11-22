#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# addtimes.rb
#
# Copyright © 2016-2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.4 (11/22/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

DEFAULT_VARNAME   = "ADDTIMES"
VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )
DCLSCOPE_LOCAL    = 1
DCLSCOPE_GLOBAL   = 2
# -----

require 'optparse'
require 'pp'
require_relative 'lib/WhichOS'
require_relative 'lib/TimeInterval'
require_relative 'lib/GetPrompted'
require_relative 'lib/ANSIseq'

# ==========

# === Main ===
options = { :operator => :add,
            :start    => nil,
            :prompt   => false,
            :os        => :linux,
            :varname   => nil,
            :dclscope  => DCLSCOPE_LOCAL,
            :noop     => false,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-p", "--prompt", "Prompt mode; can be used/combined with the",
                             "arguments (timeints) on the command-line" ) do |val|
    options[:prompt] = true
  end  # -p --prompt
  opts.on( "-o", "--operator=OP",
           /add|subtract|plus|minus/,
           "'add' (default, 'plus') or 'subtract' ('minus')" ) do |val|
    options[:operator] = val.downcase.to_sym
    options[:operator] = :add      if options[:operator] == :plus
    options[:operator] = :subtract if options[:operator] == :minus
  end  # -o --operator=OP
  opts.on( "-s", "--start=TIMEINT", "Starting time interval value; this option",
                 "is required for --operator=minus|subtract" ) do |val|
    options[:start] = val
  end  # -s --start

  opts.separator ""
  opts.on( "-r", "--variable[=VARNAME]", String,
           "Variable (DCL symbol) name for addtimes result;",
           "  default variable name is #{DEFAULT_VARNAME}1; example:",
           "  -rr and --variable=r both become variable R1" ) do |val|
    options[:varname] = ( val || DEFAULT_VARNAME ).upcase
  end  # -r --variable

  opts.separator "\n#{VMSONLY_BORDER}"
  opts.on( "-s", "--scope[=DCLSCOPE]", /GLOBAL|LOCAL/i,
           "DCL variable scope (default LOCAL, or GLOBAL)" ) do |val|
    options[:dclscope] = ( val || "LOCAL" ).upcase[0] == "L" ?
                           DCLSCOPE_LOCAL : DCLSCOPE_GLOBAL
  end  # -x --scope
  opts.separator "\n    Options here are ignored if not VMS (OpenVMS)\n#{VMSONLY_BORDEREND}\n\n"

  # -n --dryrun not implemented, not needed for this program:
  # opts.on( "-n", "--noop", "--dryrun", "--test",
  #          "Dry-run (test & display, no-op) mode" ) do |val|
  #   options[:noop]  = true
  #   options[:verbose] = true  # Dry-run implies verbose...
  # end  # -n --noop
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
  opts.banner = "  Adds or subtracts time intervals or durations." +
                "\n\n  Usage: #{PROGNAME} [options] timeint1 [timeint2...]" +
                "\n\n  where each timeintN is a time interval or duration." +
                "\n\n  A timeint value is entered as:" +
                "\n\n    M            - Minutes: an integer (no punctuation)" +
                "\n    MM:SS        - Minutes and Seconds" +
                "\n    HH:MM:SS     - Hours, Minutes and Seconds" +
                "\n    D HH:MM[:SS] - Days, Hours, Minutes and (optional) Seconds" +
                "\n\n  Note 1: To facilitate timeint entry from the Numeric Keypad, a '.' (dot/period)" +
                "\n          can substitute for a colon ':', and a '-' (dash) can substitute for the" +
                "\n          ' ' (space) after Days." +
                "\n\n  Note 2: If a data entry error (typo) is made, use either '!' (bang) or '-' (minus)" +
                "\n          to undo (reverse) that entry.  An input stack (LIFO) is maintained, so an" +
                "\n          arbitrary number of reversals can be done." +
                "\n\n  Examples:   12      = twelve minutes, zero seconds;" +
                "\n                 1:30 = a minute and a half;" +
                "\n              2:20:02 = two hours, twenty minutes and two seconds;" +
                "\n            3 3:30:03 = three days, three hours, thirty minutes and three seconds;" +
                "\n            or equivalents: 1.30; 2.20.02; 3-03.30.03; or even 3-03:30.03" +
                "\n\n"
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

if ( options[:operator] == :subtract ) && ( ! options[:start] )
  puts "%#{PROGNAME}-e-required, --start=TIMEINT required for subtract operations"
  exit false
end

# accumlates seconds, t+o be displayed as interval "d hh:mm:ss"
accint = TimeInterval.new( opts = options )

pstr = options[:start] ? accint.accumulate( options[:start] ) : "  0 00:00:00"

idx = 1  # only emit last/ultimate value as DCL symbol "#{DEFAULT_VARNAME}1"

if ARGV[0]
  # Add all given args on command-line, even if prompt-mode is requested...
  ARGV.each do | arg |
    pstr = accint.accumulate( arg )
  end
end
if options[:prompt]
  # ...Prompt user for values, show running-tape of accumulated/calc'd time
  # display current interval as prompt> -- get user's input, no default answer:
  while pstr = getprompted( "#{pstr} > ", "", true )
    break if pstr == ""
    if ( pstr == '!' ) || ( pstr == '-' )
      pstr = accint.undo
    else
      pstr = accint.accumulate( pstr )
    end
  end  # while
end

if options[:varname]
  case options[:os]
  when :linux, :unix, :windows
    # Tuck result into a shell environment variable -- Note that, for non-VMS,
    # this is *useless* (mostly), as the environment variable is created in
    # the (sub)process which is running this Ruby script, thus the parent process
    # (which com-line-ran the script) never sees the env-variable!
    # So, the following is just a "demo" --
    result = accint.to_s
    envvar = options[:varname] + "#{idx}"
    ENV[envvar] = result
    STDOUT.puts "%#{PROGNAME}-i-createenv, created shell environment variable #{envvar}, value '#{result}'" if options[:verbose]
  when :vms
    # Tuck result into a DCL Variable/Symbol --
    require 'RTL'
    result = accint.to_s.strip.sub( ' ', '-' )  # make VMS delta-datetime format "D-hh:mm:ss"
    dclsym = options[:varname] + "#{idx}"
    RTL::set_symbol( dclsym, result, options[:dclscope] )
    STDOUT.puts "%#{PROGNAME}-i-createsym, created DCL variable/symbol #{dclsym}, value '#{result}'" if options[:verbose]
  end  # case
else
  result = $stdout.tty? ? accint.to_s.trim.bold.underline : accint.to_s
  puts "\nAccumulated interval/duration: #{ result }\n"
end  # if

exit true
