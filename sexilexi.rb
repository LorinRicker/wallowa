#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# sexilexi.rb
#
# Copyright © 2012-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.4 (11/19/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'ripper'
require 'pp'
require_relative 'lib/ANSIseq'

# ==========

# Build a printable version of the code:
def prettyprint( code, bline, sfile, options )
  puts "Ruby source file: " + sfile.bold.color(:blue) if options[:verbose]
  # Compute field-width for leading line numbers
  #   = number-of-lines-in-array converted to string,
  #     then the width of that value...
  cw = code.length.to_s.length
  # Decorate each code line with its line number, right-justified:
  lncode = ""
  code.each_with_index do | line, indx |
    lncode << sprintf( "%#{cw}d| %s", indx + bline, line )
  end
  # ...and print the line-numbered code colorfully --
  sep = "-" * 32
  puts sep.bold.color(:red)
  puts lncode.rstrip.bold.color(:blue)
  puts sep.bold.color(:red)
end  # prettyprint

# Delete lines before options[:start] if specified:
def deletebeginlines( code, bline )
  bcode = []
  code.each_with_index do | line, indx |
    bcode << line if indx + 1 >= bline
  end
  return bcode.dup
end  # deletebeginlines

# Delete lines after options[:stop] if specified:
def deleteendlines( code, eline )
  ecode = []
  code.each_with_index do | line, indx |
    ecode << line if indx + 1 <= eline
  end
  return ecode.dup
end  # deleteendlines

# ==========

options = { :start   => false,
            :stop    => false,
            :srcfile => nil,
            :lexical => false,
            :parser  => false,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-b", "--start", "=N", Integer, "Start/begin-line to analyze" ) do |val|
    options[:start] = val
  end  # -b --start
  opts.on( "-e", "--stop", "=N", Integer, "Stop/end-line to analyze" ) do |val|
    options[:stop] = val
  end  # -e --stop
  opts.on( "-f", "--file", "--source", "=FILE", "Ruby source file" ) do |val|
    options[:srcfile] = val
  end  # -f --srcfile
  opts.on( "-l", "--lexical", "Display lexical analysis" ) do |val|
    options[:lexical] = true
  end  # -l --lexical
  opts.on( "-p", "--parser", "Display parser analysis" ) do |val|
    options[:parser] = true
  end  # -p --parser
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
  opts.banner = "\n  Usage: #{PROGNAME} [options]\n\n"
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

# Either inhale a Ruby source file or prompt user to enter a code-fragment:
if options[:srcfile]
  f = File.open( options[:srcfile], "r" )
  # Inhale entire file into array...
  sfile = options[:srcfile]
  acode = f.readlines
else
  sfile = "<manual code entry>"
  acode = []
  # Do homemade Readline::readline so we can catch termination Ctrl/D:
  begin
    while true
      STDOUT.print "code> "
      STDOUT.flush
      acode << STDIN.readline
    end
  rescue EOFError
    STDOUT.puts "\#<EOF>"
  end
end  # if options[:srcfile]

bline = options[:start] || 0
# Delete lines from end-of-array first: saves keeping track of how many
# lines might have been deleted from beginning of array first...
acode = deleteendlines( acode, options[:stop] ) if options[:stop]
acode = deletebeginlines( acode, options[:start] ) if options[:start]

prettyprint( acode, bline, sfile, options )

# Convert the resulting file-array into a string
# for Ripper lexical and parser analysis...
code = acode.join( "" )

pp Ripper.lex( code ) if options[:lexical]

pp Ripper.sexp( code ) if options[:parser]
