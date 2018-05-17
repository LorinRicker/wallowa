#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# rel2bin.rb
#
# Copyright © 2012-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.4 (05/17/2018)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'fileutils'
require_relative 'lib/filemagic'
require_relative 'lib/ANSIseq'
require_relative 'lib/FileEnhancements'
require_relative 'lib/StringCases'
require_relative 'lib/AskPrompted'

# Main -- Script which releases other scripts (files) to a .../<tfdir>/
#         directory for "released" execution.
#
#         Includes: i) a sanity check to prevent over-writing another
#         similarly-named script (i.e., don't over-write a Ruby script
#         with a Perl script); ii) Strips file extension from a "main"
#         script (e.g., "filecomp.rb" becomes "filecomp") for simple(r)
#         command invocation (filename must be 100% lower-case, while
#         support/include files with Mixed-Case filename are *not*
#         stripped); iii) file is copied from source directory to
#         destination directory (--bin=PATH, ENV[BIN], ENV[B], or
#         default "~/bin"), file's protection mode and its uid:gid
#         ownership are set/reset as needed.

options = { :bin     => nil,
            :mode    => nil,
            :strip   => nil,
            :test    => nil,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-b", "--bin", "=PATH_TO_BIN",
           "Path to 'bin' directory" ) do |val|
    options[:bin] = File.expand_path( val )
  end  # -b --bin
  opts.on( "-m", "--mode", "=MODE", String, /700|750|770|755|775|777/,
           "File mode (protection)" ) do |val|
    options[:mode] = '0' + val
  end  # -m --mode
  opts.on( "-s", "--strip", "Strip (force) the file extension" ) do |val|
    options[:strip] = true
  end  # -s --strip
  opts.on( "-t", "--test", "Test (rehearse) the release" ) do |val|
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
    require_relative 'lib/AboutProgram'
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] [ file-to-release | ... ]\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    options[:help] = true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

fmode      = options[:mode] || '0755'
fprot      = fmode.to_i(8)
testprefix = "%#{PROGNAME}-I-TEST, "
testindent = ' ' * testprefix.length
bangprefix = "%#{PROGNAME}-W-SHEBANG, "
bangindent = ' ' * bangprefix.length
fcount     = 0

ARGV.each do | sfile |

  fcount += 1

  # Parse the source file's basename and source directory:
  if ! File.exists?( sfile )
    $stderr.puts "%#{PROGNAME}-E-FNF, file #{sfile} not found"
    next
  end  # if sfile.exists?
  sffull = File.expand_path( sfile )
  sfdir  = File.dirname( sffull )
  sfbase = File.basename( sffull )
  sfext  = File.extname( sffull )
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, sfile: #{sfile}, sffull: #{sffull}" if options[:verbose]

  # Check the source-file's shebang line... and...
  # Determine whether or not to strip the filename's extension
  # based on whether the source file name is all lower-case
  # (it'll be a command-file name, so strip the file extension),
  # or it's a library sub-dir (it's a require or include file,
  # so do not(!) strip the file extension)...
  sflang   = sffull.parse_shebang
  shellscr = [ '.sh', '.csh' ].index( sfext )
  # Is this a library/require/include file?
  #   A trailing "/lib" is telltale, but
  #   MixedCaseFileName is a tip-off, too --
  libfile  = sfdir =~ /\/lib$/ || sfbase.isMixedCase?
  nameonly = ! libfile || shellscr || options[:strip]
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, sflang: '#{sflang}', nameonly: #{nameonly}" if options[:verbose]

  # Figure out where user's .../bin/ folder is... start with 'logical name' "bin":
  # Check com-line switch, ENV[] for 'BIN' or 'B':
  tfdir = ENV['bin']   # "logical name" -- see shell functions 'logicals' and 'deflogical'
  if ! File.directory?( tfdir )
    # use the first of these that's not nil:
    if options[:bin]
      tfdir = options[:bin]
    elsif ENV['BIN']
      tfdir = ENV['BIN']
    elsif ENV['B']
      tfdir = ENV['B']
    end  # if
  end  # if
  if ! File.directory?( tfdir )
    $stderr.puts "%#{PROGNAME}-E-NODIR, directory #{tfdir} does not exist"
    exit false  # Quit if not allowed to create the target directory...
  end  # if tfdir.exists?
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, tfdir: #{tfdir}" if options[:verbose]
  tfdirtree = File.join( tfdir, 'lib' ) if tfdir

  # Sort out the destination filespec:
  tfdir = tfdirtree if libfile  # Adjust the target-dir for a library file
  tfbase = nameonly ? File.basename( sfbase, sfext ) : sfbase
  tffull = File.join( tfdir, tfbase )
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, tffull: #{tffull}" if options[:verbose]
  tfexists = File.exist?( tffull )

  # Determine if over-copying another script with a different shebang;
  # warn if so... if same shebangs, then proceed...
  # Note: parse_shebang returns nil if target file does not exists,
  #       so this copy-test should succeed, not fail!
  tflang = tffull.parse_shebang || sflang
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, tflang: '#{tflang}'" if options[:verbose]
  if sflang != tflang
    $stderr.puts "#{bangprefix}mismatched shebang values in source and target files"
    $stderr.puts "#{bangindent}source: '#{sflang}', target: '#{tflang}'"
    $stderr.puts "#{bangindent}Action: " + "Investigate files manually to resolve...".underline
    exit false
  end  # if sflang != tflang

  if tfexists   # Check digests only if the target file exists...
                # otherwise, we're making the first copy to tfdir!
    # Check for identical contents... no need to copy if same file...
    sfdigest = sffull.msgdigest
    tfdigest = tffull.msgdigest
    if sfdigest == tfdigest
      $stderr.puts "#{testprefix}msg-digest source==target, no copy for #{sfbase}" if options[:test]
      next
    else  # Digests not same: go ahead and copy...
      $stderr.puts "#{testprefix}msg-digest source<>target, will copy #{sfbase}" if options[:test]
    end  # if sfdigest == tfdigest
  end  # if tfexists

  # Copy the source file to .../<tfdir>/:
  if options[:test]
    $stderr.puts "\n#{testprefix}" + "$ cp -v #{sffull} #{tffull}".bold
  else
    FileUtils.cp( sffull, tffull, :verbose => options[:verbose] )
  end  # if options[:test]

  # chmod and chown for eXecutable and proper file ownership:
  ownedby = File.ownedby_user( File.lstat( tffull ) )
  uid     = Process::Sys.getuid
  gid     = Process::Sys.getgid
  prcug   = File.translate_uid_gid( uid, gid )
  if options[:test]
    puts "#{testindent}" + "$ chown -v #{prcug} #{tffull}".bold if !ownedby
    puts "#{testindent}" + "$ chmod -v #{fmode} #{tffull}".bold
  else
    FileUtils.chown( uid, gid, tffull, :verbose => options[:verbose] ) if !ownedby
    FileUtils.chmod( fprot, tffull, :verbose => options[:verbose] )
  end  # if options[:test]

  $stderr.puts "" if fcount == 1
  $stderr.puts "%#{PROGNAME}-S-SUCCESS, #{sflang} script copied: '#{tffull}'"

end  # ARGV.each
