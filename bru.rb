#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# bru.rb
#
# Copyright © 2012-14 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.02 (10/28/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}.yaml.rc" )

  DEFEXCLFILE   = File.join( CONFIGDIR, 'common_rsync.excl' )
  DEFSOURCETREE = File.join( '/home', ENV['USER'], "" )  # ensure a trailing '/'
  DEFBACKUPTREE = File.join( '/media', ENV['USER'], DEFSOURCETREE )

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2
DBGLVL3 = 3

# -----

# bru provides a command line driver for routine rsync backup and restore
# operations on a known, YAML-configured /home/USER/... directory tree.
# Having written similarly-purposed scripts in bash, this Ruby implementation
# provides logical and comprehensible simplicity and maintainability, plus
# considerably better error-checking, command-line interfacing, robustness
# and recoverability.

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require_relative 'lib/StringEnhancements'
require_relative 'lib/FileEnhancements'
require_relative 'lib/ANSIseq'

# ==========

def filespec( optfile, deffile, opttext = "" )
  xfile  = optfile ? File.absolute_path( optfile ) : deffile
  xfile += '/' if File.directory?( xfile ) && xfile[-1] != '/'
  xfile = "«not found»" if ! File.exists?( xfile )
  qfile = opttext + xfile
  return qfile if opttext == ""
  return [ xfile, qfile ]
end  # filespec

def badtree( op, tree, deftree = "" )
  dir = tree || deftree
  $stderr.puts "%#{PROGNAME}-e-fnf, #{op} Directory Tree not found: #{dir}"
  exit false
end  # badtree

# ==========

options = {
            :about      => false,
            :debug      => DBGLVL0,
            :sourcetree => nil,
            :backuptree => nil,
            :recover    => false,
            :exclude    => nil,
            :noop       => false,
            :itemize    => false,
            :sudo       => "",
            :forcesave  => false,
            :verbose    => false
          }

options.merge!( AppConfig.configuration_yaml( CONFIGFILE, options ) )

optparse = OptionParser.new { |opts|
  opts.on( "-s", "--sourcetree", "=SourceDir", String,
           "Source directory tree" ) do |val|
    options[:sourcetree] = val
  end  # -s --sourcetree
  opts.on( "-b", "--backuptree", "=BackupDir", String,
           "(optional) Backup directory tree - If specified, this",
           "value overrides any other backup directory given on",
           "the command line; this value will be saved in the",
           "configuration file if --forcesave is also specified" ) do |val|
    options[:backuptree] = val
  end  # -b --sourcetree
  opts.on( "-r", "--recover", "--restore",
           "Recover (restore) the SourceDirectory from the BackupDir" ) do |val|
    options[:recover] = true
  end  # -r --recover
  opts.on( "-x", "--exclude", "=ExcludeFile", String,
           "Exclude-file containing files (patterns) to omit from this backup;",
           "if no exclude-file, specify as '--exclude-file=none'" ) do |val|
    options[:exclude] = val
  end  # -x --exclude
    opts.on( "-i", "--itemize",
           "Itemize changes (output) during file transfer" ) do |val|
    options[:itemize] = true
  end  # -i --itemize
  opts.on( "-S", "--sudo",
           "Run this backup/restore with sudo" ) do |val|
    options[:sudo] = "sudo"
  end  # -S --sudo
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
  opts.on( "-f", "--forcesave", "--update",
           "Update (force save) the configuration file" ) do |val|
    options[:forcesave] = true
  end  # -f --forcesave
  opts.on( "-v", "--verbose", "--log", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
  opts.on( "-d", "--debug", "=DebugLevel", Integer,
           "Show debug information (levels: 1, 2 or 3)" ) do |val|
    options[:debug] = val.to_i
  end  # -d --debug
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "  Usage: #{PROGNAME} [options] [BackupDir]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

# Common rsync options, always used here...
# note that --archive = --recursive --perms --links --times
#                       --owner --group --devices --specials
rcommon  = "-auh --stats"           # --archive --update --human-readable --stats
rcommon += " -n" if options[:noop]  # --dry-run
# Turn on verbose/progress output?
rverbose  = options[:verbose] ? " --progress" : ""
rverbose += " --itemize-changes" if options[:itemize]

# If an exclude-from file is specified (or default) and exists, use it:
if options[:exclude].locase == "none"
  exclfile, excloption = "«none»", ""
else
  exclfile, excloption = filespec( options[:exclude], DEFEXCLFILE, " --exclude-from=" )
end

# If a SourceDirectory is specified, us it rather than the default:
sourcedir = filespec( options[:sourcetree], DEFSOURCETREE )

# If a BackupDirectory is specified, us it rather than the default:
bdir = options[:backuptree] || ARGV[0]   # com-line's --backuptree spec trumps ARGV[0]
backupdir = filespec( bdir, DEFBACKUPTREE )

# The full rsync command with options:
rsync  = "#{options[:sudo]} rsync #{rcommon}#{rverbose}#{excloption} "
# Operation:                 v-- Restoration ----------v   v-- Backup ---------------v
rsync += options[:recover] ? "#{backupdir} #{sourcedir}" : "#{sourcedir} #{backupdir}"

# Update the config-file, at user's request:
if options[:forcesave]
  options[:forcesave] = false  # Store these values only...
  options[:sudo] = ""          # ...for these options!
  AppConfig.configuration_yaml( CONFIGFILE, options, true )  # force the save/update
end

if options[:debug] >= DBGLVL2
  op = options[:recover] ? "Recover <=" : "Backup =>"
  $stderr.puts "\n           CONFIGDIR: '#{CONFIGDIR.color(:green)}'"
  $stderr.puts "          CONFIGFILE: '#{CONFIGFILE.color(:green)}'"
  $stderr.puts "         DEFEXCLFILE: '#{DEFEXCLFILE.color(:red)}'"
  $stderr.puts "  Actual excludefile: '#{exclfile.color(:red)}'"
  $stderr.puts "    Source directory: '#{sourcedir.color(:purple)}'"
  $stderr.puts "    Backup directory: '#{backupdir.color(:purple)}'"
  $stderr.puts "           Operation:  #{op.underline.color(:purple)}"
  $stderr.puts "  Full rsync command: '$#{rsync.color(:blue)}'\n\n"
end

badtree( "Backup", backupdir, DEFBACKUPTREE ) if backupdir[0] != "/"
badtree( "Source", sourcedir, DEFSOURCETREE ) if sourcedir[0] != "/"

# %x{ #{rsync} }.each_line { |ln| $stdout.puts ln }

exit true
