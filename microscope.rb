#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# microscope.rb (formerly sexilexi.rb)
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# This program implements Ruby (MRI) code-internals output for inspection
# as inspired and specified by Pat Shaughnessy's "Ruby Under A Microscope"
# book (ISBN 978-1-59327-527-3, No Starch Press, 2014).

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.0 (12/23/2014)"
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

SEPLINE = "_" * 64

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
  puts SEPLINE.bold.color(:red)
  puts lncode.rstrip.bold.color(:blue)
  puts SEPLINE.bold.color(:red)
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

def codeout( annotation, codetext )
  puts annotation.bold.color(:red)
  if annotation[0..3] == 'YARV'
    puts codetext  # disassembled code is one long string with embedded-\n
  else
    pp codetext    # tokens and S-expressions are arrays of strings
  end
  puts SEPLINE.bold.color(:red)
end  # codeout

# ==========

options = { :start    => false,
            :stop     => false,
            :srcfile  => nil,
            :token    => false,
            :parser   => false,
            :compiler => false,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-b", "--start", "=N", Integer, "Start/begin-line to analyze" ) do |val|
    options[:start] = val
  end  # -b --start
  opts.on( "-e", "--stop", "=N", Integer, "Stop/end-line to analyze" ) do |val|
    options[:stop] = val
  end  # -e --stop
  opts.on( "-s", "--source", "=FILE", "Ruby source file" ) do |val|
    options[:srcfile] = val
  end  # -s --source
  opts.on( "-t", "--tokenize", "--lexical",
           "Display lexical (token) analysis" ) do |val|
    options[:token] = true
  end  # -t --tokenize --lexical
  opts.on( "-p", "--parser", "--sexp", "--ast",
           "Display parser (sexp/AST) analysis" ) do |val|
    options[:parser] = true
  end  # -p --parser --sexp --ast
  opts.on( "-c", "--compiler", "--yarv",
           "Display compiler (YARV) analysis" ) do |val|
    options[:compiler] = true
  end  # -c --compiler --yarv
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] [RubySourceFile]\n\n"
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

# if sourcefile was given as argument, not as --source=FILE:
options[:srcfile] ||= ARGV[0]
# (if both, then --source=FILE prevails...)

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

bline = options[:start] || 1
# Delete lines from end-of-array first: saves keeping track of how many
# lines might have been deleted from beginning of array first...
acode = deleteendlines( acode, options[:stop] ) if options[:stop]
acode = deletebeginlines( acode, options[:start] ) if options[:start]

prettyprint( acode, bline, sfile, options )

# Convert the resulting file-array into a string
# for Ripper lexical and parser analysis...
code = acode.join( "" )

codeout( 'Lexical Tokens:',
          Ripper.lex(code) ) if options[:token]
codeout( 'AST Parsed S-Expressions:',
          Ripper.sexp(code) ) if options[:parser]
codeout( 'YARV Compiled Instructions:',
          RubyVM::InstructionSequence.compile(code).disasm ) if options[:compiler]

exit true
