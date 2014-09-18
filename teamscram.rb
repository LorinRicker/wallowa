#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# teamscram.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.0 (09/17/2012)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# Create N-member teams from a class roster file

# === For command-line arguments & options parsing: ===
require 'optparse'
require 'pp'
require_relative 'Scramble'
require_relative 'StringEnhancements'
require_relative 'Prompted'
require_relative 'TermChar'
require_relative 'ANSIseq'

COMMENTMARK = '#'   # for Ruby, Perl, Python & bash (etc.) source files

STDINFD  = 0
STDOUTFD = 1

# ==========

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

def report( teams, outf )
  # Report/output the teams:
  tnum = 0
  teams.each do | t |
    tnum += 1
    outf.puts "\n#{'='*10}\n  Team #{tnum}"
    mnum = 0
    t.each do | m |
      mnum += 1
      member = m ? sprintf("\#%2d - %s", mnum, member ) : '(empty)'
      outf.puts "#{' '*4}#{member}"
    end
    outf.puts "\n  Total of #{mnum} members"
  end
  outf.puts "\n#{'='*10}\n\nTotal of #{tnum} teams"
end  # report

def process( inputf, outf, options )
  File.open( inputf ? inputf : STDINFD, "r") do | inf |
    # Instantiate a class roster, read each student's name from input file:
    roster = Scramble.new
    while line = inf.gets
      line = line.chomp
      next if line.lstrip[0] == COMMENTMARK
      next if line.collapse == ""
      roster.store( line )
    end
    # Shuffle the roster:
    roster.shuffle
    # Extract teams, n-members at a time, from roster,
    # aggregate each team into a set of teams:
    teams = []
    while ( team = roster.deal( options[:teamnumber] ) ) != nil
      teams << team
    end
    report( teams, outf )
    outf.close if outf != STDOUTFD
  end
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening input file '#{inputf}'"
  exit false
end

# ==========

options = { teamnumber: 2,   # Number of members on each team
            debug:      nil
          }

optparse = OptionParser.new { |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] [ process-id-string | ... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
    exit true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  opts.on( "-t", "-n", "--teamnumber=N", "Integer",
           "Number of members on each team" ) do |val|
    options[:teamnumber] = val || 2
  end  # -n -m --members
  opts.on( "-d", "--debug=[N]", "Turn on debugging messages (levels)" ) do |val|
    options[:debug] = val || 1
  end  # -d --debug
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
}.parse!  # leave residue-args in ARGV

process( ARGV[0], prepare( ARGV[1] ), options )
