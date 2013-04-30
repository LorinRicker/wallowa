#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# dcl.rb
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

# dcl provides command line (shell) access to a small library of string-
# transformational routines which are reminiscent of those found in the
# VMS/DCL repertory of F$* functions, callable as if these were bash
# "built-in" functions.

# Access (calls) to these functions are implemented by creating named symlinks
# for each function; these symlinks point (refer to) this dcl script itself,
# such that Ruby's $0 variable (the name of the command/file reference which
# invoked this script invocation) can dispatch execution-control to the correct
# String class method.

# Input for each function comes either from:
#
#   1) The concatenation of all non-switch (non-option) arguments on the
#      command line, joined into a single space-separated string argument.
#      For example, the string-argument for: $ upcase this "is a  " test
#      is: "this is a   test"
#
#   2) Standard Input, if there is/are no non-switch options provided on
#      the command line.

# Output from the function is written to Standard Output with no further
# embellishments or decorations (i.e., no surrounding quotations, etc.).
# For example, the output from the sample upcase function call given in 1)
# above would be: THIS IS A   TEST

# The --verbose (-v) option is for testing &/or verification of input/output
# results: thus this command will output three lines, the echoed command line,
# the annotated result, and the pure result line itself:
#
#   $ upcase -v "this is a test"
#   %upcase-I-echo,   $ upcase 'this is a test'
#   %upcase-I-result, 'THIS IS A TEST'
#   THIS IS A TEST

# Function results can be captured/assigned to a bash variable thusly:
#
#   $ var=$( upcase "this is a test" )
#   $ echo $var
#   THIS IS A TEST

# This mechanism also provides for functional results to be applied via a pipe:
#
#   $ var=$( compress "  this   is a test   " | upcase )
#   $ echo $var
#   THIS IS A TEST

# Intermediate results can be checked/tracked with --verbose:
#
#   var=$( compress -v "   this is a      test   " | upcase -v )
#   %compress-I-echo,   $ compress '   this is a      test   '
#   %compress-I-result, 'this is a test'
#   %upcase-I-echo,   $ upcase 'this is a test'
#   %upcase-I-result, 'THIS IS A TEST'
#   $ echo $var
#   THIS IS A TEST

# One function, edit, allows a list of edits to be applied to the argument
# string, which is an alternative way to the pipe-method above to execute
# a sequence of functional filters:
#
#   $ edit -v "compress,upcase" "   this is a      test   "
#   %dcl-I-echo,   $ edit '   this is a      test   '
#   %dcl-I-result, 'THIS IS A TEST'
#   THIS IS A TEST

# One dcl function is special: dclsymlink -- This function checks and verifies
# each of its arguments, which name function symlink(s): it does for each named
# function(s) what the --symlinks option (below) does for all functions.
#
#   $ dclsymlink capcase locase [...]
#   %dcl-S-created, symlink ~/bin/capcase created
#   %dcl-S-created, symlink ~/bin/locase created

# The --symlinks (-s) option checks &/or verifies each function in ALL_LINKS
# (including itself), and either creates a symlink to the dcl script if it does
# not (yet) exist, or complains with an error message if a previous (ordinary)
# file by that name already exists.
#
# The dcl --symlinks option serves as an installation bootstrap step, as well
# as a periodic &/or troubleshooting verification step; e.g.:
#
#   $ dcl [--verbose] --symlinks   # verify &/or install all function symlinks
#   %dcl-S-created, symlink ~/bin/capcase created
#   %dcl-S-verified, symlink ~/bin/collapse verified
#   %dcl-S-verified, symlink ~/bin/compress verified
#   ...
#   %dcl-S-created, symlink ~/bin/dclsymlink created

# -----

    PATH = File.dirname $0
 DCLNAME = File.join( PATH, "dcl" )             # hard-wire this name...
      DN = "-> #{DCLNAME}"
PROGNAME = File.basename DCLNAME                # not "$0" here!...
  PROGID = "#{PROGNAME} v1.04 (10/23/2012)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'StringEnhancements'
require 'pp'
require_relative 'ANSIseq'

# ==========

def dclsymlink( syms )
  syms.each do |s|
    slnk = File.join( PATH, s )
    if File.symlink?( slnk )
      # See http://ruby.runpaint.org/ref/file for documentation of new methods
      # File.readlink (used here) and File.realpath...
      if File.readlink( slnk ) == DCLNAME
        $stderr.puts "%#{PROGNAME}-I-verified, symlink #{slnk} is verified (#{DN})"
      else
        $stderr.puts "%#{PROGNAME}-E-badlink,  symlink #{slnk} is wrong (not#{DN})"
      end  # if File.identical?( DCLNAME, slnk )
    else
      if ! File.file?( slnk )  # no ordinary file collision?
        File.symlink( DCLNAME, slnk )
        $stderr.puts "%#{PROGNAME}-S-created,  symlink #{slnk} created (#{DN})"
      else
        $stderr.puts "%#{PROGNAME}-E-conflict, file #{slnk} exists, no symlink created"
      end  # if ! File.file?( slnk )
    end  # if File.symlink( slnk )
  end  # syms.each
end  # dclsymlink

def getargs( options )
  if ARGV[0]
    args = ARGV.join( " " )              # all args into one big sentence...
  else                                   # ...or from std-input
    args = $stdin.readline.chomp if !options[:symlinks]
  end  # if ARGV[0]
  return args
end  # getargs

# ==========

ALL_LINKS = %w{ capcase locase upcase
                collapse compress
                cjust ljust rjust
                edit element
                length pluralize
                substr thousands titlecase
                trim trim_leading trim_trailing
                uncomment
                dclsymlink }

options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] [ dclfunction ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    fperline = 5                        # functions per line
    i        = 0                        # a counter
    hlp      = "Available functions: "
    hlplen   = hlp.length
    ALL_LINKS.each do | a |  # concatenate a ,-sep & measured list of functions
      i += 1
      hlp += a
      hlp += ", " if i < ALL_LINKS.size
      hlp += "\n" + " "*hlplen if i % fperline == 0 && i < ALL_LINKS.size
    end  # ALL_LINKS.each
    puts "\n#{hlp}"                     # print formated functions-help
    options[:help] = true
    exit true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  opts.on( "-l", "--links", "--symlinks",
           "Create or verify symlinks for all functions" ) do |val|
    options[:symlinks] = true
  end  # -l --symlinks --links
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

action = File.basename( $0 ).downcase  # $0 is name of invoking symlink...

if options[:symlinks]
  dclsymlink( ALL_LINKS )       # set &/or verify ALL_LINKS symlinks
  exit true
else

  case action                     # Dispatch the command-line action;
                                  # invoking symlink's name is $0 ...
  when "capcase"
    args = getargs( options )
    result = args.capcase

  when "collapse"
    args = getargs( options )
    result = args.collapse

  when "compress"
    args = getargs( options )
    result = args.compress

  when "length"
    args = getargs( options )
    result = args.length         # String class does this one directly

  when "locase"
    args = getargs( options )
    result = args.locase         # String class does this one directly

  when "thousands"
    args = getargs( options )
    result = args.thousands

  when "titlecase"
    args = getargs( options )
    result = args.titlecase

  when "trim"
    args = getargs( options )
    result = args.strip          # String class does this one directly

  when "trim_leading"
    args = getargs( options )
    result = args.lstrip         # String class does this one directly

  when "trim_trailing"
    args = getargs( options )
    result = args.rstrip         # String class does this one directly

  when "uncomment"
    args = getargs( options )
    result = args.uncomment

  when "upcase"
    args = getargs( options )
    result = args.upcase         # String class does this one directly

  # when "«+»"
  #   args = getargs( options )
  #   result = args.«+»

  when "cjust"
    # $ cjust width "String to center-justify..."
    ## >> How to default width to terminal-width, and how to specify padchr? Syntax?
    width  = ARGV.shift.to_i
    # padchr = ARGV.shift
    args   = getargs( options )
    result  = args.center( width )

  when "ljust"
    # $ ljust width "String to center-justify..."
    width  = ARGV.shift.to_i
    # padchr = ARGV.shift
    args   = getargs( options )
    result  = args.ljust( width )

  when "rjust"
    # $ rjust width "String to center-justify..."
    width  = ARGV.shift.to_i
    # padchr = ARGV.shift
    args   = getargs( options )
    result  = args.rjust( width )

  when "edit"
    # $ edit "func1,func2[,...]" "String to filter"
    #   where "func1,funct2[,...]" -- the editlist -- is required
    editlist = ARGV.shift            # assign and remove arg [0]
    args = getargs( options )
    result = args.edit( editlist )

  when "element"
    # $ element 2 [";"] "String;to;extract;an;element;from"
    #   where first arg is the element-number (zero-based) to extract,
    #   and second arg is (optional) element separator (default ",");
    #   note that if length of second arg is > 1, it defaults, and
    #   remainder of string is the string to filter
    elem = ARGV.shift.to_i           # assign and remove arg [0]
    sep  = ARGV[0].length == 1 ? ARGV.shift : ","  # and arg [1]
    args = getargs( options )
    result = args.element( elem, sep )

  when "pluralize"
    # $ pluralize word howmany [irregular]
    word      = ARGV.shift                  # assign and remove arg [0]
    howmany   = ARGV.shift.to_i             # and arg [1]
    irregular = ARGV[0] ? ARGV.shift : nil  # and (optional) arg [2]
    # args = getargs( options )             # ...ignore rest of com-line
    result = word.pluralize( howmany, irregular )

  when "substr"
    # $ substr start len "String to extract/substring from..."
    start = ARGV.shift.to_i
    len   = ARGV.shift.to_i
    args  = getargs( options )
    result = args[start,len]      # String class does this one directly

  when "dclsymlink"
    dclsymlink( ARGV )            # Set &/or verify this action verb symlink
    exit true

  end  # case $PROGNAME

  if options[:verbose]
    $stderr.puts "%#{PROGNAME}-I-echo,   $ " + "#{action}".underline + " '#{args}'"
    $stderr.puts "%#{PROGNAME}-I-result, " + "'#{result}'".bold
  end  # if options[:verbose]

  $stdout.print result  # Print filtered result to std-output

end  # if options[:symlink]
