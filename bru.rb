#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# bru.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.4 (09/03/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

  CONFIGTYPE = ".yaml.rc"
   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, "#{PROGNAME}#{CONFIGTYPE}" )

  DEFEXCLFILE   = File.join( CONFIGDIR, 'common_rsync.excl' )
  DEFSOURCETREE = File.join( '/home', ENV['USER'], "" )  # ensure a trailing '/'
  DEFBACKUPTREE = File.join( '/media', ENV['USER'], DEFSOURCETREE )

  MELLIPSE = "···"  # mid-dot ellipse

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
require 'open3'
require 'pp'
require_relative 'lib/appconfig'
require_relative 'lib/FileEnhancements'
require_relative 'lib/ANSIseq'
require_relative 'lib/AskPrompted'
require_relative 'lib/TermChar'

# ==========

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

def fit_filespec( ln, pat, twidth, itemize )
  return ln if not itemize                  # --itemize-changes asserted?
  m = pat.match( ln )
  if m
    case m[1][0..1]  # first-two characters of itemized changes field
    when 'cd'  # directory created
      fs = "create: #{m[2]}"
    when '.d'  # directory updated
      fs = "update: #{m[2]}"
    when '>f'  # file sent/updated
      fs = m[4]
      wdth = twidth - 7  # for padding and MELLIPSE
      if fs.length > wdth
        fn = File.basename( fs, '.*' )
        ft = File.extname( fs )
        w  = wdth - ft.length
        fs = fn[0..w] + MELLIPSE + ft
      end
      fs = "  #{fs}"
    else       # catch-all -- will improve itemize codes based on observances...
      fs = "  #{m[4]} (--itemize-changes: #{m[1]})"
    end  # case
    return "| #{fs}"
  else
    return "! #{ln}"  # other normal rsync output...
  end
end  # fit_filespec

# ==========

# params will always be saved/used to/from a config-file (YAML) --
params =  { :sourcetree => nil,
            :backuptree => nil,
            :exclude    => nil,
            :checksum   => false,
            :stats      => false,
            :itemize    => false,
            :progress   => false
          }

# options are *never* saved/used to/from a config-file --
options = { :recover    => false,
            :noop       => false,
            :rawout     => false,
            :sudo       => "",
            :use        => nil,
            :write      => nil,
            :verbose    => false,
            :debug      => DBGLVL0,
            :about      => false
          }

# Consume the *default* config-file --
params.merge!( AppConfig.configuration_yaml( CONFIGFILE, params ) ) if File.exist?( CONFIGFILE )

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

# Parse the command line --
optparse = OptionParser.new { |opts|
  opts.on( "-s", "--sourcetree", "=SourceDir", String,
           "Source directory tree; what you're backing up..." ) do |val|
    params[:sourcetree] = val
  end  # -s --sourcetree
  opts.on( "-b", "--backuptree", "=BackupDir", String,
           "(optional) Backup directory tree - If specified, this",
           "value overrides any other backup directory given on",
           "the command line; this value will be saved in the",
           "configuration file if --update is also specified" ) do |val|
    params[:backuptree] = val
  end  # -b --backuptree
  opts.on( "-e ExcludeFile", "--exclude", String,
           "Exclude-file containing files (patterns) to omit",
           "from this backup; if there is no exclude-file,",
           "your personal default exclude-file is used:",
           "  #{DEFEXCLFILE}" ) do |val|
    params[:exclude] = val || DEFEXCLFILE
  end  # -e --exclude
  opts.on( "-c", "--checksum",
           "Use checksum for file differences (not mod-time & size)" ) do |val|
    params[:checksum] = val
  end  # -c --checksum
  opts.on( "-t", "--[no-]stats",
           "display summary statistics at end of file transfer" ) do |val|
    params[:stats] = val
  end  # -t --stats
  opts.on( "-p", "--[no-]progress",
           "display file progress during file transfer" ) do |val|
    params[:progress] = val
  end  # -p --progress
  opts.on( "-i", "--[no-]itemize-changes",
           "Itemize changes during file transfer" ) do |val|
    params[:itemize] = val
  end  # -i --itemize
  opts.separator ""   # ---------
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
    options[:sudo] = "sudo "
  end  # -S --sudo
  opts.on( "-U ConfigFile", "--use", "--read", String,
           "Use (read) a configuration file which was",
           "previously saved in #{CONFIGDIR}/" ) do |val|
    cfile = val.to_s
    cfile = cfile + CONFIGTYPE if File.extname( cfile ) == ''
    cfile = File.expand_path( cfile, CONFIGDIR )
    if File.exist?( cfile )
      options[:use] = cfile
    else
      $stderr.puts "%#{PROGNAME}-e-fnf, configuration file #{cfile} not found"
      exit false
    end
  end  # -U --use --read
  opts.on( "-C [ConfigFile]", "--write", "--save", String,
           "Write (save) the configuration file from",
           "the current #{PROGNAME} command line's options",
           "(default: #{CONFIGFILE})" ) do |val|
    cfile = val.to_s
    cfile = CONFIGFILE if File.basename( cfile ) == ''
    cfile = cfile + CONFIGTYPE if File.extname( cfile ) == ''
    cfile = File.expand_path( cfile, CONFIGDIR )
    options[:write]  = cfile || CONFIGFILE
  end  # -C --write --save
  opts.on( "-o", "--raw-output",
           "Display raw rsync output lines, unfiltered;",
           "content depends on itemize-changes, stats,",
           "progress and/or verbose" ) do |val|
    options[:rawout] = val
  end  # -o --raw-output
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

# Use (read) a named config-file --
AppConfig.configuration_yaml( options[:write], params, true ) if options[:write]
# And (re)save a named config-file (might be a different filename than options[:write]) --
options.merge!( AppConfig.configuration_yaml( options[:use], params ) ) if options[:use]

# If a BackupDirectory is specified, use it rather than the default;
# if given, the --backuptree spec trumps ARGV[0]:
options[:backuptree] ||= ARGV[0]
backupdir = dirspec( options[:backuptree], DEFBACKUPTREE )

# Common rsync options, always used here...
# note that --archive = --recursive --perms --links --times
#                       --owner --group --devices --specials
rcommon  = "-auhm"     # --archive --update --human-readable --prune-empty-dirs
rcommon += " --stats" if options[:stats] || options[:verbose]
rcommon += " --checksum" if options[:checksum]
rcommon += " --dry-run"  if options[:noop]

# Turn on progress output? Using --info=FLAGS rather than --progress (etc)
# See man rsync and rsync --info=help for details --
rverbose  = options[:progress] ? " --info=progress1,backup1" : ""
rverbose += options[:itemize]  ? " --itemize-changes" : ""

# If an exclude-from file is specified (or default) and exists, use it --
exclfile, excloption = excludespec( options[:exclude], DEFEXCLFILE, " --exclude-from=" )

# If a SourceDirectory is specified, use it rather than the default --
sourcedir = dirspec( options[:sourcetree], DEFSOURCETREE )

# Form the full rsync command with options --
#   Here's where we swap sourcedir<-->backupdir for a restore, if needed --
rsync  = " #{options[:sudo]}/usr/bin/rsync #{rcommon}#{rverbose}#{excloption} "
# Operation:                 v-- Restore --------------v   v-- Backup ---------------v
rsync += options[:recover] ? "#{backupdir} #{sourcedir}" : "#{sourcedir} #{backupdir}"

# Sanity check/display if the user's asked for this --
if options[:verbose] || options[:debug] >= DBGLVL1
  op = options[:recover] ? "Recover <=" : "Backup =>"
  $stderr.puts "\n           Operation:  #{op.underline.color(:blue)}"
  $stderr.puts "  Full rsync command: '$#{rsync.color(:blue)}'\n\n"
end
if options[:debug] >= DBGLVL2
  $stderr.puts "\n           CONFIGDIR: '#{CONFIGDIR.color(:green)}'"
  $stderr.puts "          CONFIGFILE: '#{CONFIGFILE.color(:green)}'"
  $stderr.puts "         DEFEXCLFILE: '#{DEFEXCLFILE.color(:red)}'"
  $stderr.puts "  Actual excludefile: '#{exclfile.color(:red)}'"
  $stderr.puts "    Source directory: '#{sourcedir.color(:purple)}'"
  $stderr.puts "    Backup directory: '#{backupdir.color(:purple)}'"
end

# Check directory-trees' existence, make the target dir-tree if its missing --
if options[:recover]
  dir_error( "Backup", backupdir          ) if not File.exists?( backupdir )
  make_tree( "Source", sourcedir, options ) if not File.exists?( sourcedir )
else
  dir_error( "Source", sourcedir          ) if not File.exists?( sourcedir )
  make_tree( "Backup", backupdir, options ) if not File.exists?( backupdir )
end

# === Execute the external command ===

# If it's a "short-list" of files to transfer, the %x{} method returns rsync
# output lines at end-of-subprocess, works well enough.  But if the file-list
# is long/big, rsync will work for "a long time" to completion before any
# output is available for print here...
$stderr.puts "\n%#{PROGNAME}-i-noop, ======= DRY-RUN MODE =======".color(:red) if options[:noop]
$stderr.puts "%#{PROGNAME}-i-popen2e_working, rsync output..."
xstat = 0

if not options[:rawout]
  # pat = /^[fdLDScstpoguax><h.*+? ]{11}    # 11-char --itemize-changes -i field
  #        \                                # followed by a literal space
  #        ( (\/?                           #   optional leading / absolute path
  #           ([^\/\\]*)[\/\\])*            #   zero-or-many sub-directories
  #          ([^\/\\]*) )                   #   and the filename
  #       /x
  pat = /^([fdLDScstpoguaxh><.*+? ]{11})\ (\/?([^\/\\]*[\/\\])*([^\/\\]*))/
  twidth = TermChar.terminal_width
end
# This is now a job for Open3.popen2e()...
Open3.popen2e( rsync ) do | stdin, stdouterr, thrd |
  stdouterr.each { |ln|
    if not options[:rawout]
      $stdout.puts "#{fit_filespec( ln, pat, twidth, options[:itemize] )}"
    else
      $stdout.puts "| #{ln}"
    end
  }
  xstat = thrd.value.exitstatus  # Process::Status
end

exit xstat
