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
  PROGID = "#{PROGNAME} v1.2 (11/19/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}.yaml.rc" )

  DEFEXCLFILE   = File.join( CONFIGDIR, 'common_rsync.excl' )
  DEFSOURCETREE = File.join( '/home', ENV['USER'], "" )  # ensure a trailing '/'
  DEFBACKUPTREE = File.join( '/media', ENV['USER'], DEFSOURCETREE )

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

# bru provides a command line driver for routine rsync backup and restore
# operations on a known, YAML-configured /home/USER/... directory tree.
# Having written similarly-purposed scripts in bash, this Ruby implementation
# provides logical and comprehensible simplicity and maintainability, plus
# considerably better error-checking, command-line interfacing, robustness
# and recoverability.

require 'optparse'
require 'fileutils'
require 'pp'
require_relative 'lib/StringEnhancements'
require_relative 'lib/FileEnhancements'
require_relative 'lib/ANSIseq'
require_relative 'lib/AskPrompted'

# ==========

def config_save( opt )
  # opt is a local copy of options, so we can patch a few
  # values without disrupting the original/global hash --
  opt[:about]     = false
  opt[:debug]     = DBGLVL0
  opt[:recover]   = false
  opt[:noop]      = false
  opt[:sudo]      = ""
  opt[:update]    = false
  opt[:verbose]   = false
  AppConfig.configuration_yaml( CONFIGFILE, opt, true )  # force the save/update
end  # config_save

def excludespec( optfile, deffile, opttext = "" )
  fil  = optfile ? File.expand_path( optfile ) : File.expand_path( deffile )
  if File.exists?( fil )
    opt = opttext + fil
  else
    fil = "«not found»"
    opt = ""
  end
  return [ fil, opt ]
end  # excludespec

def dirspec( optdir, defdir )
  dir  = optdir ? File.expand_path( optdir ) : File.expand_path( defdir )
  dir += '/' if File.directory?( dir ) && dir[-1] != '/'
  return dir
end  # dirspec

def dir_error( op, dir )
  $stderr.puts "%#{PROGNAME}-e-fnf, #{op} Directory Tree not found: #{dir}"
  exit false
end  # dir_error

def make_tree( op, dir, options )
  answer = askprompted( "#{op} Directory Tree does not exist; create it" )
  dir_error( op, dir ) if not answer  # "No"? -- error-msg and exit
  begin
    FileUtils.mkdir_p( dir, :mode => 0700,
                       :noop => options[:noop], :verbose => options[:verbose] )
  rescue SystemCallError => e
    $stderr.puts "%#{PROGNAME}-f-priv, cannot create directory tree (FileUtils.mkdir_p)"
    $stderr.puts "-e-exception, #{$!}"
    recovery = "sudo mkdir -pv #{dir}"
    $stderr.puts "-i-recovery, >> $ #{recovery.underline.color(:red)}"
    dir_error( op, dir )
  end
end  # make_tree

# ==========

options = { :sourcetree => nil,
            :backuptree => nil,
            :exclude    => nil,
            :itemize    => false,
            :recover    => false,
            :noop       => false,
            :sudo       => "",
            :update     => false,
            :verbose    => false,
            :debug      => DBGLVL0,
            :about      => false
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
           "configuration file if --update is also specified" ) do |val|
    options[:backuptree] = val
  end  # -b --backuptree
  opts.on( "-e", "--exclude", "[=ExcludeFile]", String,
           "Exclude-file containing files (patterns) to omit",
           "from this backup; if there is no exclude-file,",
           "the default is used:",
           "  #{DEFEXCLFILE}" ) do |val|
    options[:exclude] = val || DEFEXCLFILE
  end  # -e --exclude
    opts.on( "-i", "--[no-]itemize",
           "Itemize changes (output) during file transfer" ) do |val|
    options[:itemize] = val
  end  # -i --itemize
  opts.separator ""
  opts.separator "    The options below are always saved in the configuration file"
  opts.separator "    in their 'off' or 'default' state:"
  opts.on( "-R", "--recover", "--restore",
           "Recover (restore) the SourceDirectory from the BackupDir",
           "Note: Do not change the values of either --sourcetree or",
           "      --backuptree... Use the same values as given for",
           "      the original backup operation; this option properly",
           "      uses these to restore the BackupDir to SourceDir.\n\n" ) do |val|
    options[:recover] = true
  end  # -R --recover
  opts.on( "-S", "--sudo",
           "Run this backup/restore with sudo" ) do |val|
    options[:sudo] = "sudo"
  end  # -S --sudo
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
  opts.on( "-u", "--update", "--save",
           "Update (save) the configuration file; a configuration",
           "file is automatically created if it doesn't exist:",
           "#{CONFIGFILE}" ) do |val|
    options[:update] = true
  end  # -u --update
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] [BackupDir]" +
                "\n\n   The target BackupDir (directory) can be specified either as the command"   +
                "\n   argument or as the value of the option --backuptree.  If both are provided," +
                "\n   then the command argument is used.  The SourceDir is always specified as"    +
                "\n   the value of the --sourcetree option.\n\n"
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

# Common rsync options, always used here...
# note that --archive = --recursive --perms --links --times
#                       --owner --group --devices --specials
rcommon  = "-auh --stats"           # --archive --update --human-readable --stats
rcommon += " -n" if options[:noop]  # --dry-run
# Turn on verbose/progress output?
rverbose  = options[:verbose] ? " --progress" : ""
rverbose += options[:itemize] ? " --itemize-changes" : ""

# If an exclude-from file is specified (or default) and exists, use it:
exclfile, excloption = excludespec( options[:exclude], DEFEXCLFILE, " --exclude-from=" )

# If a SourceDirectory is specified, us it rather than the default:
sourcedir = dirspec( options[:sourcetree], DEFSOURCETREE )

# If a BackupDirectory is specified, use it rather than the default;
# the --backuptree spec, if given, trumps ARGV[0]:
options[:backuptree] ||= ARGV[0]
backupdir = dirspec( options[:backuptree], DEFBACKUPTREE )

# The full rsync command with options:
rsync  = "#{options[:sudo]} rsync #{rcommon}#{rverbose}#{excloption} "
# Operation:                 v-- Restoration ----------v   v-- Backup ---------------v
rsync += options[:recover] ? "#{backupdir} #{sourcedir}" : "#{sourcedir} #{backupdir}"

# Update the config-file, at user's request:
config_save( options ) if options[:update]

if options[:debug] >= DBGLVL2
  op = options[:recover] ? "Recover <=" : "Backup =>"
  $stderr.puts "\n           CONFIGDIR: '#{CONFIGDIR.color(:green)}'"
  $stderr.puts "          CONFIGFILE: '#{CONFIGFILE.color(:green)}'"
  $stderr.puts "         DEFEXCLFILE: '#{DEFEXCLFILE.color(:red)}'"
  $stderr.puts "  Actual excludefile: '#{exclfile.color(:red)}'"
  $stderr.puts "    Source directory: '#{sourcedir.color(:purple)}'"
  $stderr.puts "    Backup directory: '#{backupdir.color(:purple)}'"
  $stderr.puts "           Operation:  #{op.underline.color(:blue)}"
  $stderr.puts "  Full rsync command: '$#{rsync.color(:blue)}'\n\n"
end

if options[:recover]
  dir_error( "Backup", backupdir          ) if not File.exists?( backupdir )
  make_tree( "Source", sourcedir, options ) if not File.exists?( sourcedir )
else
  dir_error( "Source", sourcedir          ) if not File.exists?( sourcedir )
  make_tree( "Backup", backupdir, options ) if not File.exists?( backupdir )
end

%x{ #{rsync} }.lines { |ln| $stdout.puts ln }

exit true
