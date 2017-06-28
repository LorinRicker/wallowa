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
  PROGID = "#{PROGNAME} v1.2 (06/27/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

USAGE_MSG = "  Usage: #{PROGNAME} [options] file1 [ file2 ]..."

DEFAULT_MDIGEST   = "SHA256"
DEFAULT_VARNAME   = "CHECKSUM\$#{PROGNAME.upcase}"
VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )
DCLSCOPE_LOCAL    = 1
DCLSCOPE_GLOBAL   = 2

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
      cdigest, fname = line.chomp.split
      if ( ! options[:digest] )
        fext = File.extname( cname )
        if m = mdpat.match( fext )  # assignment, not equality-test!
          options[:digest] = m[1].upcase
          STDERR.puts "%#{PROGNAME}-i-matched, auto-matched message digest #{m[0]}" if options[:verbose]
        else
          STDERR.puts "%#{PROGNAME}-e-nomatch, failed to auto-match any message digest"
          exit false
        end
      end  # if
      mdigest = fname.msgdigest( options[:digest] )
      if mdigest == cdigest
        $stdout.puts "#{fname}: OK"
      else
        $stdout.puts "#{fname}: FAILED"
        failed_count += 1
      end
    end  # lines.each
  end  # args.each
  if failed_count > 0
    msg = "#{PROGNAME}: WARNING: #{failed_count} computed checksum" +
          "#{failed_count > 1 ? 's' : ''} did NOT match"
    $stdout.puts msg
  end  # if failed_count > 0
end  # check_files

def digest_files( args, options )
  mdigest = fname = ""
  args.each do | arg |
    fname = (File.dirname( arg ) != '.') ? File.expand_path( arg ) : arg
    mdigest = fname.msgdigest( options[:digest] )
  end  # args.each
  [ mdigest, fname ]  # return value
end # digest_files

def display_instructions
  $stdout.puts <<~EOInstructions

  Use:
    $ #{PROGNAME} [options] file1 [ file2 ]...

  Examples:
    $ #{PROGNAME} foo.txt               # Create #{DEFAULT_MDIGEST} (default) digest of foo.txt
    $ #{PROGNAME} foo1 foo2 foo3        # Compute #{DEFAULT_MDIGEST} digests of three files
    $ #{PROGNAME} --digest=md5 foo4     # Create MD5 digest of foo4
    $ #{PROGNAME} foo2 > foo2.sha512    # Output #{DEFAULT_MDIGEST} digest to file foo2.sha512
    $ #{PROGNAME} --check foo2.sha512   # Check (recompute) actual digest of
                                 #   file in foo2.sha512 using #{DEFAULT_MDIGEST} algorithm,
                                 #   and file named in this signature file
    $ #{PROGNAME} -c -mrmd160 foo2.md5  # Check actual digest of file in foo.md5, but
                                 #   is ".md5" file extension a lie (wrong)?

  This program is intended as a drop-in replacement for *nix utility commands
  like md5sum and sha(256,384,512)sum, and produces output which is formatted
  identically to these programs (note: two spaces between values):

      "hash-digest-value  path-filename"

  Conventions:
    * Default message (hash) digest algorithm is #{DEFAULT_MDIGEST}.
    * Available algorithms are MD5, SHA1, SHA256, SHA384, SHA512 and RIPEMD160;
        see https://en.wikipedia.org/wiki/Cryptographic_hash_function and/or
        https://en.wikipedia.org/wiki/Comparison_of_cryptographic_hash_functions
        for (much) more information.
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
    * If --check (-c) is used without --digest (-m), then the digest algorithm
        is determined by (a regexp pattern match is attempted) from the file's
         type; name output digest files accordingly.  File extensions like these
         will work: foo.txt.md5, foo.txtmd5, foo.md5, FOO.TXT_MD5 or FOO.MD5 (VMS).
    * Regexp pattern matching for hash algorithms is case insensitive.

    On VMS:
    * This utility program brings modern message digest functionality to the VMS
        (OpenVMS) environment, supplementing its native CHECKSUM command.
    * Default behavior is to output the hash digest to SYS\$OUTPUT, just like the
        CHECKSUM command (program) does.  #{PROGNAME} also, as a side-effect, creates a
        local-scope symbol called #{DEFAULT_VARNAME} by default (again, similar to the
        CHECKSUM command's local symbol CHECKSUM\$CHECKSUM).

    #{PROGID} -- #{AUTHOR}
  EOInstructions
end # display_instructions

# === Main ===
options = { :digest       => DEFAULT_MDIGEST,
            :check        => false,
            :output       => nil,
            :varname      => nil,
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
  options[:digest] = ( val || DEFAULT_MDIGEST )
  end  # -m --digest
  opts.on( "-c", "--check",
           "Cross-check message-digest(s) from file(s); for",
          "  this option, file1 [file2]... must be message-",
          "  digest output files" ) do |val|
    options[:check] = true
  end  # -c --check
  opts.on( "--instructions", "--man",
           "Display extended instructions for #{PROGNAME}" ) do |val|
    options[:instructions] = true
    display_instructions
    exit true
  end  # --instructions

  opts.separator "\n#{VMSONLY_BORDER}"
  opts.on( "-o", "--output[=OUTFILE]", String,
           "File name for redirected program output; required",
           "  for VMS, as DCL doesn't recognize '>' for output",
           "  redirection." ) do |val|
    options[:output] = val
  end  # -o --output
  opts.on( "-r", "--variable[=VARNAME]", String,
           "Variable (symbol) name for expression result;",
           "  default variable name is #{DEFAULT_VARNAME},",
           "  which is always a local (scope) DCL symbol." ) do |val|
    options[:varname] = ( val || DEFAULT_VARNAME ).upcase
  end  # -r --variable
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

$stdout = File.open( options[:output], 'w' ) if options[:output]

if ARGV.length > 0
  if options[:check]  # check existing *.mdigest file against actual source file(s) --
    check_files( ARGV, options )
  else  # generate "msgdigest  filename" output(s), which can be redirected --
    mdigest, fname = digest_files( ARGV, options )
    case options[:os]
    when :linux, :unix, :windows
      $stdout.puts "#{mdigest}  #{fname}"
    when :vms
      if options[:varname]
        # Tuck result into a local DCL Variable/Symbol --
        require 'RTL'
        RTL::set_symbol( options[:varname], mdigest, DCLSCOPE_LOCAL )
        $stdout.puts "%#{PROGNAME}-i-createsym, created DCL variable/symbol #{DEFAULT_VARNAME}, value '#{mdigest}'" if options[:verbose]
      else
        $stdout.puts "#{mdigest}  #{fname}"
      end  # if options[:varname]
    end  # case options[:os]
  end
else
  $stdout.puts USAGE_MSG
end

exit true
