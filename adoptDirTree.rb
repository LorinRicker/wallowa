#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# adoptDirTree.rb  -- called by adopt[.sh] in order to wrap with sudo
#
# Copyright © 2012-13 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = "adopt"  # File.basename $0
  PROGID = "#{PROGNAME} v1.2 (06/10/2013)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'fileutils'
require 'find'
require_relative 'ANSIseq'
require_relative 'FileEnhancements'
require_relative 'StringEnhancements'

# Main -- Script to ensure that all files in a directory(-tree)
#         are owned by the uid:gid of the parent directory.

options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] [ dirtree-path | ... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
  end  # -a --about
  opts.on( "-d", "--debug", "debug mode: show all internal traces" ) do |val|
    options[:debug] = true
  end  # -d --debug
  opts.on( "-m", "--mode", "=MODE", Integer,
           /600|644|664|666|700|750|770|755|775|777/,
           "File mode (protection)" ) do |val|
    options[:mode] = '0'+ val
  end  # -m --mode
  opts.on( "-t", "--test", "Test (rehearse) the adoption" ) do |val|
    options[:test] = true
  end  # -t --test
  opts.on( "-v", "--verbose", "Verbose mode: show all internal traces" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

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

  Find.find( tdir ) do | sf |

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
