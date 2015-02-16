#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# wordfrequencies.rb
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
# Usage:  $ ./wordfrequencies [infile] [outfile]
#         $ ./wordfrequencies foo.rb                  # output to STDOUT
#         $ ./wordfrequencies foo.rb foo.nocomments
#         $ ./wordfrequencies <foo.rb >foo.nocomments
#         $ cat foo.rb | ./wordfrequencies

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.9 (02/15/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

STDINFD  = 0
STDOUTFD = 1

DEFAULT_LIMIT = 20

TRIM_COMMON_WORDS = %w{ a an and but or not at as by between
                        to too also
                        i i'm i'll me my other
                        you your you're we we're our ours us
                        they their they're them
                        he she his her her's
                        it its it's itself if
                        the that this there here these those
                        then than has have had
                        is be been are was were will when which
                        of in into on for with from have
                        do don't did didn't won't were
                        get got so who what when how
                        can could would should may might
                        can't couldn't wouldn't
                        only very much must most often about almost
                        all any both many some few none more less
                        because well just like tho' though while
                        yes no maybe
                        ''
                      }.sort

require 'optparse'
require 'pp'

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

def process( inputf, outf )
  wordfreq = Hash.new( 0 )
  wordpat  = /[^a-zA-Z0-9'-]/   # Non-word character(s)
  File.open( inputf ? inputf : STDINFD, "r" ) do | inf |
    while line = inf.gets
      line = line.chomp
      next if line.lstrip == ''
      line.split( wordpat ).each do | word |
        # Don't even count tiny-words like "a":
        wordfreq[word.downcase] += 1 if word.length > 1
      end
    end  # while
  end
  wordfreq
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening input file '#{inputf}'"
  exit false
end

def dump( wf )
  wfdsize = 12
  wflen   = wf.length
  if wf.length > wfdsize
    print '['
    (0..wfdsize-1).each { |i| pp wf[i] }
    puts '  ...'
    (wflen-4..wflen-1).each { |i| pp wf[i] }
    puts "]\n\n"
  else
    pp wf
  end
end

def report( wordfreq, options )
  wf = wordfreq.sort { | a, b | b[1] <=> a[1] }  # Descending order
  if options[:trim]
    # Throw away common words:
    wf.delete_if { |word| TRIM_COMMON_WORDS.index(word[0]) }
  end
  dump( wf ) if options[:debug]
  printed = i = 0
  while i < wf.length && printed < options[:limit]
    if wf[i][0].size > options[:size]
      printf( "  %16s : %6d\n", "'#{wf[i][0]}'", wf[i][1] )
      printed += 1
    end
    i += 1
  end
end

# ============

# === Main ===
options = { :limit   => DEFAULT_LIMIT,
            :size    => 1,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-l", "--limit", "=N", Integer, "Top N words to report" ) do |val|
    options[:limit] = val.to_i
  end  # -l --limit
  opts.on( "-s", "--size", "=N", Integer, "Word-length longer than N" ) do |val|
    options[:size] = val.to_i
  end  # -s --size
  opts.on( "-t", "--trim", "Trim away common words" ) do |val|
    options[:trim] = true
  end  # -t --trim
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
  opts.banner = "\n  Usage: #{PROGNAME} [options]" +
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

pp options if options[:verbose]

report( process( ARGV[0], prepare( ARGV[1] ) ), options )
