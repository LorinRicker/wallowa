#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# teamscram.rb
#
# Copyright © 2014-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.4 (02/16/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

# Create N-member teams from a class roster file

require 'optparse'
require 'pp'
require_relative 'lib/Scramble'
require_relative 'lib/StringEnhancements'
require_relative 'lib/Prompted'
require_relative 'lib/TermChar'
require_relative 'lib/ANSIseq'

COMMENTMARK = '#'   # for Ruby, Perl, Python & bash (etc.) source files

STDINFD  = 0
STDOUTFD = 1

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

options = { :teamsize => 2,   # Default number of members on each team
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-t", "-n", "--teamsize=N", Integer,
           "Number of members on each team" ) do |val|
    options[:teamsize] = val || DEFAULT_TN
  end  # -n -m --members
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] infile" +
                "\n\n   where infile is the file (path) which contains the pool of names" +
                "\n   from which to form teams, one name per line.\n\n"
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

options[:teamsize] = DEFAULT_TN if options[:teamsize] <= 0

options[:verbose] = true if options[:debug] > DBGLVL0

process( ARGV[0], prepare( ARGV[1] ), options )
