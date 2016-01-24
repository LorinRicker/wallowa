#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# adoptdirtree.rb  -- called by adopt[.sh] in order to wrap with sudo
#
# Copyright © 2012-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = "adopt"  # File.basename $0
  PROGID = "#{PROGNAME} v1.6 (02/16/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'fileutils'
require 'find'
require_relative 'lib/ANSIseq'
require_relative 'lib/FileEnhancements'
require_relative 'lib/StringEnhancements'

# ==========

# Main -- Script to ensure that all files in a directory(-tree)
#         are owned by the uid:gid of the parent directory.

options = { :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-m", "--mode", "=MODE", String,
           /600|644|664|666|700|750|770|755|775|777/,
           "File mode (protection mask)" ) do |val|
    options[:mode] = '0' + val
  end  # -m --mode
  opts.on( "-t", "--test", "Test (rehearse) the adoption" ) do |val|
    options[:test] = true
  end  # -t --test
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] [ dirtree-path | ... ]\n\n"
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

ARGV << "./*" if !ARGV[0]  # default is current-dir if none specified

fmode      = options[:mode] || '0644'
fprot      = fmode.to_i(8)
testprefix = "%#{PROGNAME}-I-TEST, "
testindent = ' ' * testprefix.length

ARGV.each do | td |

  tdir = File.dirname( File.expand_path( td ) )
  if ! File.directory?( tdir )
    puts "%#{PROGNAME}-E-NODIR, directory #{tdir} does not exist"
    exit false
  end  # if dfdir.exists?
  puts "%#{PROGNAME}-I-DEBUG, tdir: #{tdir}" if options[:debug]

  fstat = File.lstat( tdir )
  tduid = fstat.uid
  tdgid = fstat.gid
  prcug = File.translate_uid_gid( tduid, tdgid )
  puts "#{testindent} parent directory ownership '#{prcug}'" if options[:debug]

  Find.find( td ) do | sf |

    next if ( sf == '.' ) || ( sf == '..' )

    ownedby = File.ownedby_user( File.lstat( sf ), tduid, tdgid )

    # Parse the source file's basename and source directory:
    tfile = File.expand_path( sf )
    puts "%#{PROGNAME}-I-DEBUG, sf: #{tfile}" if options[:debug]

    # chmod and chown for eXecutable and proper file ownership:
    if options[:test]
      puts "#{testprefix}$ chown -v #{prcug} #{tfile}".bold if !ownedby
      puts "#{testprefix}$ chmod -v #{fmode} #{tfile}".bold if options[:mode]
    else
      FileUtils.chown( tduid, tdgid, tfile, :verbose => options[:verbose] ) if !ownedby
      FileUtils.chmod( fprot, tfile, :verbose => options[:verbose] ) if options[:mode]
    end  # if options[:test]

  end  # Find.find( tdir )

end  # ARGV.each
