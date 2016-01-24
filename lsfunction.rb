#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# lsfunction.rb
#
# Copyright © 2012-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.8 (12/29/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/dpkg_utils'
require_relative 'lib/Prompted'
require_relative 'lib/TermChar'
require_relative 'lib/ANSIseq'
require 'pp'

# List bash functions -- This script captures the raw output from
# an executed "set" command (as a subshell/fork) and parses it
# according to com-line options.
#
# The bash built-in "set" command, when invoked with no options
# or parameters, will list all environment variables and function
# definitions.  But, since this script will execute the "set" in
# a forked process (which copies exported functions and variables),
# this script's "vision" will be limited to functions which are
# exported when defined: "function foo() {...}; export -f foo"
# and/or "export var[=val]" and/or "declare -x name".
#
# There is no bash command or built-in to list bash function
# definitions, either in aggregate, or separately; this script
# fills a practical need:  It provides a convenient way to list
# and review in-memory function and env-var definitions.

# Although functions, as well as aliases, are very useful, both
# are difficult to remember, especially if you've got a large
# number of them, and you can remember only a few that you use
# frequently.  In fact, bash functions are to be preferred over
# aliases: functions embody custom functionality and can accept
# parameters; aliases cannot.
#
# "set" generates output containing both variable and function
# definitions; "export -p" outputs exported environment variable
# definitions ("name"s in the man bash page) only.

# ==========

def list_it( lines, count, msize, name = nil, lbl = nil )
  puts "\n" + "# ===== #{lbl}#{name} =====".bold if lbl
  lines.each do | df |
    puts df
  end  # lines.each
  puts "\n" + "# ----- end #{lbl}#{name} -----".bold if lbl
  puts "  ** #{lbl.capitalize} count: #{count}" if count
  puts "  ** Memory size (bytes): #{msize}" if msize
end  # list_it

def compile_regex( name, csense, rexend )
  # Compile an advanced RegEx:
  # 1. Use "%" as wildcard, so shell doesn't glob on "*":
  namepat = name.gsub( /\%/, "\\w*" )
  # 2. Enable/disable case-sensitive match:
  cs = csense ? "?-imx:" : "?i-mx:"
  # Tricky! Start-anchor; double-((...)) inner () applies the "cs" flags,
  #         the outer (()) marks a capture-group, all followed by the
  #         "rexend" literal pattern!
  return "\\A((#{cs}#{namepat}))#{rexend}"
end  # compile_regex

def find_func( lines, name, options )
  the_func = []
  in_func  = false
  fname    = ""
  patstart = compile_regex( name, options[:casesensitive], "\\s*\\(\\)" )
  patend   = "\\A\\s*}"
  if options[:verbose]
    puts "     name: '#{name}'"
    puts " patstart: '#{patstart.to_s}'"
    puts "   patend: '#{patend.to_s}'"
  end  # if options[:verbose]
  lines.each do | ln |
    # Read through lines looking for first match patstart:
    #   funcname ()
    # when found, collect subsequent lines into the_func...
    #   ...
    # until a line matches patend...
    #   }
    ln.rstrip!  # trim-trailing
    case
    when ln.match( /#{patstart}/ )
      m = Regexp.last_match   # Grab the regex data that got us here...
      fname = m[1]            # the captured name, esp. if wildcarded
      if options[:verbose]
        puts "start #{fname} ln: '#{ln}'"
        pp m
      end  # if
      in_func = true
      $FMSIZE += ln.bytesize + 1  # account for eol-<lf>
      $FCOUNT += 1
      the_func << "\nfunction " + ln
    when ln.match( /#{patend}/ )
      if in_func
        puts "end ln: '#{ln}'" if options[:verbose]
        in_func = false
        $FMSIZE += ln.bytesize + 1  # account for eol-<lf>
        the_func << ln + "  # end function #{fname}"
      end  # if in_func
    else
      if in_func
        puts "body ln: '#{ln}'" if options[:verbose]
        $FMSIZE += ln.bytesize + 1  # account for eol-<lf>
        the_func << ln
      end  # if in_func
    end  # case
  end  # lines.each
  count = options[:count] ? $FCOUNT : nil
  msize = options[:msize] ? $FMSIZE : nil
  lbl = "function"
  lbl = $FCOUNT > 1 ? lbl + "s" : lbl
  hdr = $FCOUNT > 1 ? "" : " #{fname}"
  list_it( the_func, count, msize, hdr, lbl ) if ! the_func.empty?
end  # find_func

def find_envar( lines, name, options )
  the_envar = []
  ename     = ""
  evalue    = ""
  pat       = compile_regex( name, options[:casesensitive], "=(.*)" )
  if options[:verbose]
    puts "     name: '#{name}'"
    puts "      pat: '#{pat}'"
  end  # if options[:verbose]
  lines.each do | ln |
    # Read through lines looking for environment variable:
    #   var=value
    # when found, collect each matching envar into the_envar...
    if ln.match( /#{pat}/ )
      ename  = $1  # captured name, especially if wildcarded
      evalue = $2  # captured value (currently unused)
      $EMSIZE += ln.bytesize + 1  # account for eol-<lf>
      $ECOUNT += 1
      the_envar << ln + "   # '#{evalue}'"
    end  # if ln.match()
  end  # lines.each
  count = options[:count] ? $ECOUNT : nil
  msize = options[:msize] ? $EMSIZE : nil
  lbl = "environment variable"
  lbl = $ECOUNT > 1 ? lbl + "s" : lbl
  hdr = $ECOUNT > 1 ? "" : " #{ename.upcase}"
  list_it( the_envar, count, msize, hdr, lbl ) if ! the_envar.empty?
end  # find_envar

# ==========

options = { :envar           => false,
            :func            => true,   # default is show functions
            :both            => false,
            :count           => false,
            :msize           => false,
            :caseinsensitive => false,
            :verbose         => false,
            :debug           => DBGLVL0,
            :about           => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-e", "--envar", "--env", "--var",
           "List environment variable definition(s)" ) do |val|
    options[:envar] = true
  end  # -e --envar --env --var
  opts.on( "-f", "--func", "--function",
           "List function definition(s) (default)" ) do |val|
    options[:func] = true
  end  # -f --func --function
  opts.on( "-b", "--both", "List both function and environment variable definition(s)" ) do |val|
    options[:both] = true
  end  # -b --both
  opts.on( "-c", "--count", "List count(s) of functions &/or environment variables" ) do |val|
    options[:count] = true
  end  # -c --count
  opts.on( "-m", "--memsize", "--msize", "List size (memory) of functions &/or environment variables" ) do |val|
    options[:msize] = true
  end  # -m --memsize
  opts.on( "-s", "--casesensitive", "--sensitive", "Case sensitive search/matching" ) do |val|
    options[:casesensitive] = true
  end  # -s --casesensitive --sensitive
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] [ funcname | envarname | ... ]"     +
              "\n\n     1. Each 'funcname' or 'envarname' can contain wildcard(s) '%'," +
              "\n        e.g., f% (starts with 'f'), %doc% (containing 'doc')"          +
              "\n     2. Search/matching is case insensitive by default"                +
              "\n     3. -b (both) is implied if neither -f nor -e are asserted\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
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

# do both!...
options[:func] = options[:envar] = true if options[:both]

ARGV[0] ||= "\\w+"  # default (missing arg) means "any/all"

# Global counters, not the best Ruby, but expedient and simple here:
$FCOUNT = $ECOUNT = 0
$FMSIZE = $EMSIZE = 0

ARGV.each do | arg |

  # Invoke bash in forked subshell: -c gives it a command string "set",
  # not a file, to execute.  The bash set command spits out exported
  # functions from memory according to its own ideas of formatting and
  # indentation, and stripped of any source-file comments.
  # We just echo these lines with minimal amendment:
  lines = %x{ bash -c set }.split( "\n" )  # an array of lines

  find_func( lines, arg, options )  if options[:func]
  find_envar( lines, arg, options ) if options[:envar]

end  # ARGV.each
