#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# msgd.rb
#
# Copyright © 2016-2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# VMS (OpenVMS) has a CHECKSUM command, but its best message digest
# algorithm is (currently) MD5.  Cannot do SHA*, etc.
#
# But wait -- with VMS Ruby, we've got more!  Why not implement the
# advanced message digest algorithms with Ruby for VMS?

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.1 (06/27/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

USAGE_MSG = "  Usage: #{PROGNAME} [options] file1 [ file2 ]..."

VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )

require 'optparse'
require 'pp'
require_relative 'lib/WhichOS'
require_relative 'lib/filemagic'
## require_relative 'lib/TermChar'

# ==========

def check_files( args, options )
  mdpat = Regexp.new( /.*(SHA1|SHA256|SHA384|SHA512|MD5|RIPEMD160|RMD160).*/i )
  failed_count = 0
  args.each do | cname |
    lines = IO.readlines( cname )
    lines.each do | line |
      cdigest, fname = line.split
      if ( ! options[:digest] )
        fext = File.extname( cname )
        if m = mdpat.match( fext )  # assignment, not equality-test!
          options[:digest] = m[0][1..m.length+1].upcase
          STDERR.puts "%#{PROGNAME}-i-matched, auto-matched message digest #{m[0]}" if options[:verbose]
        else
          STDERR.puts "%#{PROGNAME}-e-nomatch, failed to auto-match any message digest"
          exit false
        end
      end  # if
      mdigest = fname.msgdigest( options[:digest] )
      if mdigest == cdigest
        STDOUT.puts "#{fname}: OK"
      else
        STDOUT.puts "#{fname}: FAILED"
        failed_count += 1
      end
    end  # lines.each
  end  # args.each
  if failed_count > 0
    msg = "#{PROGNAME}: WARNING: #{failed_count} computed checksum" +
          "#{failed_count > 1 ? 's' : ''} did NOT match"
    STDOUT.puts msg
  end  # if failed_count > 0
end  # check_files

def digest_files( args, options )
  args.each do | fname |
    fname = File.expand_path( fname ) if File.dirname( fname ) != '.'
    mdigest = fname.msgdigest( options[:digest] )
    STDOUT.puts "#{mdigest}  #{fname}"
  end  # args.each
end # digest_files

def display_instructions
  STDOUT.puts <<~EOInstructions
  #{PROGID} -- #{AUTHOR}

  Examples:
    $ #{PROGNAME} foo.txt               # Create MD5 (default) digest of foo.txt
    $ #{PROGNAME} foo1 foo2 foo3        # Compute MD5 digests of three files
    $ #{PROGNAME} --digest=sha512 foo4  # Create SHA512 digest of foo4
    $ #{PROGNAME} foo2 > foo2.md5       # Output MD5 digest to file foo2.md5
    $ #{PROGNAME} --check foo2.md5      # Check (recompute) actual digest of
                                 #   file in foo2.md5 using MD5 algorithm,
                                 #   and file named in this signature file
    $ #{PROGNAME} -c -msha512 foo2.md5  # Check actual digest of file in foo.md5, but
                                 #   is ".md5" file extension a lie (wrong)?

  Conventions:
    * Default message (hash) digest algorithm is MD5.
    * Available algorithms are MD5, SHA1, SHA256, SHA384, SHA512 and RIPEMD160;
        see https://en.wikipedia.org/wiki/Cryptographic_hash_function and/or
        https://en.wikipedia.org/wiki/Comparison_of_cryptographic_hash_functions
        for (much) more information.
    * This program is intended as a drop-in replacement for *nix utility commands
        like md5sum and sha(256,384,512)sum, and attempts to produce output which
        is formatted identically to these programs:
        "hash-digest-value  path-filename"  -- Note: two spaces between values.
    * If command-line's file argument(s) is entered as a simple file name (and
        found in the current directory), then "path-filename" is simply the
        "file.ext" -- If the file argument includes any portion of a path, then
        the file's specification is fully expanded to the absolute file-spec:
        "/path/.../file.ext"
    * Simple file names (in output digest files) are "portable" in the sense that
        no reliance on file path conventions are required; the file to process is
        assumed to be found in "the current directory."
    * Name output digest files (>) with a file extension which is the same as
        the message digest algorith -- ".md5" for MD5, ".sha384" for SHA384, etc.
    * If --check (-c) is used, then the file argument(s) is (are) processed as
        (output) digest files, not as files to calculate a digest for.
    * If --check (-c) is used with --digest=DIGEST (-mDIGEST), then "DIGEST" is
        the hash algorithm which is used.
    * If --check (-c) is used without --digest (-m), then the hash digest algorithm
        is determined by (a regexp pattern match is attempted) from the file's type;
        please name output digest files accordingly.  File extensions like these will
        work: foo.txt.md5, foo.txtmd5, FOO.TXT_MD5 or FOO.MD5 (VMS), or foo.md5
    * Regexp pattern matching for hash algorithms is case insensitive.
    * This utility program brings modern message digest functionality to the VMS
        (OpenVMS) environment, supplementing its native CHECKSUM command.
  EOInstructions
end # display_instructions

# === Main ===
options = { :digest       => nil,
            :check        => false,
            :instructions => nil,
            :noop         => false,
            :verbose      => false,
            :debug        => DBGLVL0,
            :about        => false
          }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-m", "--digest[=DIGEST]", /SHA1|SHA256|SHA384|SHA512|MD5|R.*MD160/i,
           "Message digest to use:",
           "  MD5 (d), SHA[256,384,512], SHA1 or R[IPEMD]160" ) do |val|
  options[:digest] = val || "MD5"
  end  # -m --digest
  opts.on( "-c", "--check",
           "Cross-check message-digest(s) from file(s); files",
          "  file1 [file2]... must be message-digest output files" ) do |val|
    options[:check] = true
  end  # -c --check
  opts.on( "--instructions",
           "Display extended instructions for #{PROGNAME}" ) do |val|
    options[:instructions] = true
    display_instructions
    exit true
  end  # --instructions

  opts.separator "\n#{VMSONLY_BORDER}"
  # opts.on( "-s", "--scope[=DCLSCOPE]", /GLOBAL|LOCAL/i,
  #          "DCL variable scope (default LOCAL, or GLOBAL)" ) do |val|
  #   options[:dclscope] = ( val || "LOCAL" ).upcase[0] == "L" ?
  #                          DCLSCOPE_LOCAL : DCLSCOPE_GLOBAL
  # end  # -x --scope
  opts.separator "\n    Options here are ignored if not VMS (OpenVMS)\n#{VMSONLY_BORDEREND}\n\n"

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
    require_relative 'lib/AboutProgram'
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n#{USAGE_MSG}" +
                "\n\n    where file1 ... is (are) either:" +
                "\n      a) File(s) to calculate a message (hash) digest;" +
                "\n      b) Digest file(s) to cross-check." +
                "\n\n  See Instructions (--instructions) for more information.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    # $stdout.puts "«+»Additional Text«+»"
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

options[:os] = WhichOS.identify_os

pp options if options[:debug] >= DBGLVL2

if ARGV.length > 0
  if options[:check]  # check existing *.mdigest file against actual source file(s) --
    check_files( ARGV, options )
  else  # generate "msgdigest  filename" output(s), which can be redirected --
    digest_files( ARGV, options )
  end
else
  STDOUT.puts USAGE_MSG
end

exit true
