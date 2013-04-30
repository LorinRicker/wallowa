#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# rel2bin.rb
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.5 (10/22/2012)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'fileutils'
require_relative 'ANSIseq'
require_relative 'FileEnhancements'
require_relative 'StringEnhancements'

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

options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] [ file-to-release | ... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
  end  # -a --about
  opts.on( "-b", "--bin", "=PATH",
           "Path to 'bin' directory" ) do |val|
    options[:bin] = File.expand_path( val )
  end  # -b --bin
  opts.on( "-m", "--mode", "=MODE", Integer, /700|750|770|755|775|777/,
           "File mode (protection)" ) do |val|
    options[:mode] = '0'+ val
  end  # -m --mode
  opts.on( "-s", "--strip", "Strip (force) the file extension" ) do |val|
    options[:strip] = true
  end  # -s --strip
  opts.on( "-t", "--test", "Test (rehearse) the release" ) do |val|
    options[:test] = true
  end  # -t --test
  opts.on( "-v", "--verbose", "Verbose mode: show all internal traces" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

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
  # or it's Mixed-Case (it's typically an include or require
  # file, so don't strip the file extension)...
  sflang   = File.parse_shebang( sffull )
  shellscr = [ '.sh', '.csh' ].index( sfext )
  nameonly = ! sfbase.isMixedCase? || shellscr || options[:strip]
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, sflang: '#{sflang}', nameonly: #{nameonly}" if options[:verbose]

  # Figure out where user's .../bin/ folder is:
  # Check com-line switch, ENV[] for 'BIN' or 'B', etc:
  if options[:bin]
    tfdir = options[:bin]
  elsif ENV['BIN']
    tfdir = ENV['BIN']
  elsif ENV['B']
    tfdir = ENV['B']
  else
    tfdir = '~/bin'
  end  # if
  if ! File.directory?( tfdir )
    $stderr.puts "%#{PROGNAME}-E-NODIR, directory #{tfdir} does not exist"
    exit false
  end  # if tfdir.exists?
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, tfdir: #{tfdir}" if options[:verbose]

  # Sort out the destination filespec:
  tfbase = nameonly ? File.basename( sfbase, sfext ) : sfbase
  tffull = File.join( tfdir, tfbase )
  $stderr.puts "%#{PROGNAME}-I-VERBOSE, tffull: #{tffull}" if options[:verbose]
  tfexists = File.exist?( tffull )

  # Determine if over-copying another script with a different shebang;
  # warn if so... if same shebangs, then proceed...
  # Note: File.parse_shebang returns nil if target file does not exists,
  #       so this copy-test should succeed, not fail!
  tflang = File.parse_shebang( tffull ) || sflang
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
    sfdigest = File.msgdigest( sffull )
    tfdigest = File.msgdigest( tffull )
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
