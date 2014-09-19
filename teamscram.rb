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
  PROGID = "#{PROGNAME} v1.0 (09/18/2012)"
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

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2
DBGLVL3 = 3

DEFAULT_TN = 2  # default number of members per team (options[:teamsize])

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

def report( teams, outf, combos )
  # Report the nCk:
  ln = '-' * ( combos.length + 4 )
  outf.puts "\n#{ln}"
  outf.puts "| #{combos.bold} |"
  outf.puts "#{ln}\n"
  # Report/output the teams:
  tnum = 0
  teams.each do | t |
    tnum += 1
    tn = "Team #{tnum}".bold.underline
    outf.puts "\n #{tn}"
    tcnt = mnum = 0
    t.each do | m |
      mnum += 1
      tcnt += 1 if m
      member = sprintf("\#%2d - %s", mnum, m ? m : '(empty)' )
      outf.puts "#{' '*4}#{member}"
    end
    outf.puts "\n  Total of #{tcnt} members"
  end
  tn = "Total of #{tnum} teams".color(:red).bold
  outf.puts "\n#{tn}"
  outf.puts "\nTeams assigned at #{Time.now}"
end  # report

def process( inputf, outf, options )
  File.open( inputf ? inputf : STDINFD, "r") do | inf |
    # Instantiate a class roster, read each student's name from input file:
    roster = Scramble.new
    while line = inf.gets
      line = line.chomp
      puts "line: '#{line}'" if options[:debug] >= DBGLVL2
      next if line.lstrip[0] == COMMENTMARK
      next if line.collapse == ""
      roster.store( line )
    end
    # Shuffle the roster:
    roster.shuffle
    roster.to_s if options[:debug] >= DBGLVL1
    # Extract teams, n-members at a time, from roster,
    # aggregate each team into a set of teams:
    teams = []
    exhausted = false
    until exhausted
      team, exhausted = roster.deal( options[:teamsize] )
      pp team if options[:debug] >= DBGLVL2
      teams << team
    end
    puts "\nTeams: #{teams}" if options[:debug] >= DBGLVL1
    report( teams, outf, roster.report_combination( options[:teamsize] ) )
    outf.close if outf != STDOUTFD
  end
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening input file '#{inputf}'"
  exit false
end

# ==========

options = { teamsize: 2,   # Number of members on each team
            debug:      DBGLVL0
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
  opts.on( "-t", "-n", "--teamsize=N", Integer,
           "Number of members on each team" ) do |val|
    options[:teamsize] = val || DEFAULT_TN
  end  # -n -m --members
  opts.on( "-d", "--debug=[N]", Integer,
           "Turn on debugging messages (levels)" ) do |val|
    options[:debug] = val || DBGLVL1
  end  # -d --debug
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
}.parse!  # leave residue-args in ARGV

options[:teamsize] = DEFAULT_TN if options[:teamsize] <= 0

options[:verbose] = true if options[:debug] > DBGLVL0

process( ARGV[0], prepare( ARGV[1] ), options )
