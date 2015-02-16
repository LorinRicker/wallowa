#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# fixcopyright.rb
#
# Copyright © 2014-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Tallies word frequencies in a source-code file.
# Uses STDIN and STDOUT, filenames on com-line, including redirection,
#   so this program can be used as a filter in a pipeline...
#
# Usage:  $ ./fixCopyright` [infile] [outfile]
#         $ ./fixCopyright` foo.rb                  # output to STDOUT
#         $ ./fixCopyright` foo.rb foo.nocomments
#         $ ./fixCopyright` <foo.rb >foo.nocomments
#         $ cat foo.rb | ./fixCopyright`

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.0 (02/16/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

STDINFD  = 0
STDOUTFD = 1

require 'optparse'
require 'fileutils'
require 'pp'

require_relative 'lib/StringUpdater'

# ============

def prepare( outfile )
  if outfile
    outf = File.open( outfile, 'w' )
  else
    outf = File.new( STDOUTFD, 'w' )
  end
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening output file (no such dir/path)"
  exit false
rescue IOError => e
  STDERR.puts "%#{PROGNAME}-e-errout, error opening output file or stream"
  exit false
end

def process( inputf, outf, options )
  return unless outf
  File.open( inputf ? inputf : STDINFD, "r" ) do | inf |
    while ln = inf.gets
      ln = ln.chomp
      # Simple optimization: don't bother siccing full pattern match on
      # the line unless it actually contains the string 'Copyright'...
      ln = ln.updateCopyright( updtoyear: options[:copyrightyear],
                                verbose: options[:verbose] ) if ln.index( 'Copyright' )
      outf << "#{ln}\n"
    end  # while
  end
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening input file '#{inputf}'"
  exit false
end

# ============

# === Main ===
options = { :copyrightyear => nil,
            :backup        => nil,
            :noop          => nil,
            :verbose       => false,
            :debug         => DBGLVL0,
            :about         => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-c", "--copyrightyear", "=YEAR", String,
           "Year to set upper copyright date" ) do |val|
    options[:copyrightyear] = val
  end  # -c --copyrightyear
  opts.on( "-b", "--backup",
           "Create backup file before updating source" ) do |val|
    options[:backup] = val
  end  # -b --backup
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] file [...file]" +
                "\n\n     Tallies the frequencies of words in a document.\n\n"
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

options[:verbose] = options[:debug] if options[:debug]
foptions = { :verbose => options[:verbose], :noop => options[:noop] }
tmpext   = '.tmp~'
bckext   = '.backup'

ARGV.each do | arg |
  f = arg + ( options[:backup] ? bckext : tmpext )
  FileUtils.cp( arg, f, foptions )
  process( f, prepare( arg ), options )
  FileUtils.rm( f, options ) if File.extname( f ) == tmpext  # delete temp-file
end
