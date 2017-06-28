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
  PROGID = "#{PROGNAME} v1.4 (06/28/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

USAGE_MSG = "  Usage: #{PROGNAME} [options] file1 [ file2 ]... [ > outfile ]"

DEFAULT_MDIGEST   = "SHA256"
DEFAULT_VARNAME   = "CHECKSUM\$#{PROGNAME.upcase}"
VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )
DCLSCOPE_LOCAL    = 1
DCLSCOPE_GLOBAL   = 2

MSGDIG_PAT = Regexp.new( /.*(SHA256|SHA384|SHA512|SHA1|MD5|RIPEMD160|RMD160).*/i )
PRSMDG_PAT = Regexp.new(    /SHA256|SHA384|SHA512|SHA1|MD5|R[IPEMD]*160/i        )

DOT = '.'

require 'optparse'
require 'pp'
require_relative 'lib/WhichOS'
require_relative 'lib/filemagic'
## require_relative 'lib/TermChar'

# ==========

def ext_to_digest( filespec, options )
  fext = File.extname( filespec )
  if m = MSGDIG_PAT.match( fext )  # assignment, not equality-test!
    STDERR.puts "%#{PROGNAME}-i-matched, auto-matched message digest #{m[1]}" if options[:verbose]
    m[1]  # Return the matched digest name
  else
    STDERR.puts "%#{PROGNAME}-f-nomatch, failed to auto-match any message digest"
    exit false  # ...No Return!... abort
  end
end # ext_to_digest

def output_ext_from_digest( options )
  filespec = options[:output]
  fext = File.extname( filespec )
  if m = MSGDIG_PAT.match( fext )  # assignment, not equality-test!
    filespec   # file name's extension matches desired/selected digest
  else
    fname = File.basename( filespec, fext )
    # Is filespec a VMS-fully-uppercase filename?
    #   If so, use uppercase digest name, else lowercase:
    fext  = ( fname != fname.upcase) ? options[:digest].downcase : options[:digest]
    fname = fname + DOT + fext
    fpath = File.dirname( filespec )
    if ( fpath != DOT )  # no path given?
      File.join( fpath, fname )
    else
      fname
    end
  end
end # output_ext_from_digest

def check_files( args, options )
  failed_count = 0
  args.each do | mdfname |
    lines = IO.readlines( mdfname )
    lines.each do | line |
      cdigest, cname = line.chomp.split  # the digest and file to check
      if File.exists?( cname )
        # Always use the message digest file's extension
        #  to attempt to parse out the digest to use:
        options[:digest] = ext_to_digest( mdfname, options )
        # Recalculate the file-to-check's digest and compare
        thisdigest = cname.msgdigest( options[:digest] )
        if thisdigest == cdigest
          $stdout.puts "#{cname}: OK"
        else
          $stdout.puts "#{cname}: FAILED"
          failed_count += 1
        end
      else
        STDERR.puts "%#{PROGNAME}-e-fnf, file not found: \"#{cname}\""
      end  # if File.exists?( cname )
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
    if File.exists?( arg )
      fname = (File.dirname( arg ) != '.') ? File.expand_path( arg ) : arg
      mdigest = fname.msgdigest( options[:digest] )
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
    else
      STDERR.puts "%#{PROGNAME}-e-fnf, file not found: \"#{arg}\""
    end  # if File.exists?( arg )
  end  # args.each
end # digest_files

def display_instructions
  # (VMS) Ruby v2.2.2 bug (or restriction):
  #   Does not correctly parse tilde-form "<<~EOFLABEL".
  #   Fall-back to strict "<<EOFLABLE" form.
  $stdout.puts <<EOInstructions

  Usage:
    $ #{USAGE_MSG}

  Examples --
  Calcluating message digests:
    $ #{PROGNAME} foo.txt               # Create #{DEFAULT_MDIGEST} (default) digest of foo.txt
    $ #{PROGNAME} foo1 foo2 foo3        # Compute #{DEFAULT_MDIGEST} digests of three files
    $ #{PROGNAME} --digest=md5 foo4     # Create MD5 digest of foo4

  Message digest output files:
    $ #{PROGNAME} foo2 -ofoo2           # Output #{DEFAULT_MDIGEST} digest to file foo2.sha256

  Checking a message digest using an output file:
    $ #{PROGNAME} --check foo2.sha256   # Check (recompute) actual digest of the file
                                 #   in foo2.sha256 using #{DEFAULT_MDIGEST} algorithm,
                                 #   and compare it to the message digest in
                                 #   this message digest file
    $ #{PROGNAME} -c -msha384 foo2.md5  # Check actual digest of file in foo.md5, but
                                 #   is ".md5" file extension a lie (wrong)?

  This program is intended as a drop-in replacement for *nix utility commands
  like md5sum and sha(256,384,512)sum, and produces output which is formatted
  identically to these programs (note: two spaces between values):

      "hash-digest-value  path-filename"

  Notes:
    * Default message (hash) digest algorithm is #{DEFAULT_MDIGEST}.
    * Available algorithms are SHA256, SHA384, SHA512, RIPEMD160, MD5 and SHA1;
        see https://en.wikipedia.org/wiki/Cryptographic_hash_function and/or
        https://en.wikipedia.org/wiki/Comparison_of_cryptographic_hash_functions
        for (much) more information.  SHA1 and MD5 are deprecated as insecure.
    * If command-line's file argument(s) is entered as a simple file name (and
        found in the current directory), then "path-filename" is simply the
        "file.ext" -- If the file argument includes any portion of a path, then
        the file's specification is fully expanded to the absolute file-spec:
        "/path/.../file.ext"
    * Simple file names (in output digest files) are "portable" in the sense that
        no reliance on file path conventions are required; the file to process is
        assumed to be found in "the current directory."
    * Create message digest output files with --output=FILE (-oFILE) rather than
        with the >-redirection operator, as the option engages program logic to
        ensure that the file's extention (type) matches the message digest name.
    * Name output digest files (>) with a file extension which is the same as
        the message digest algorith: ".sha384" for SHA384, etc.
    * But it's simpler to just specify the output's file name only (not the file
        extension) and let #{PROGNAME} fill in the correct extension.
    * If --check (-c) is used, then the file argument(s) is (are) processed as
        (output) digest files, not as files to calculate a digest for.
    * If --check (-c) is used with --digest=DIGEST (-mDIGEST), then "DIGEST" is
        the hash algorithm which is used.
    * If --check (-c) is used without --digest (-m), then the digest algorithm
        is determined by (a regexp pattern match is attempted) from the file's
         type; name output digest files accordingly.  File extensions like these
         will work: foo.txt.md5, foo.txtmd5, foo.md5, FOO.TXT_MD5 or FOO.MD5 (VMS).
         In this case, the regexp pattern matching is case insensitive.

    On VMS:
    * This utility program brings modern message digest functionality to the VMS
        (OpenVMS) environment, supplementing its native CHECKSUM command.
    * Default behavior is to output the hash digest to SYS\$OUTPUT, just like the
        CHECKSUM command (program) does.  #{PROGNAME} also, as a side-effect, creates a
        local-scope symbol called #{DEFAULT_VARNAME} by default (again, similar to the
        CHECKSUM command's local symbol CHECKSUM\$CHECKSUM).
    * Create message digest output files with --output=FILE (-oFILE), as the
        >-redirection operator is not available on the DCL command line; this
        option engages program logic to ensure that the file's extention (type)
        matches the message digest name.

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
  opts.on( "-m", "--digest[=DIGEST]", PRSMDG_PAT,
           "Message digest to use:",
           "  SHA256 (d), SHA384, SHA512, R[IPEMD]160",
           "  SHA1 or MD5 (note that SHA1 and MD5 are",
           "  deprecated for anything other than casual,",
           "  non-secure use)." ) do |val|
    options[:digest] = ( val || DEFAULT_MDIGEST ).upcase
    options[:digest] = 'RIPEMD160' if ( options[:digest][0] == 'R' and
                                        options[:digest][-3..-1] == '160')
  end  # -m --digest
  opts.on( "-o", "--output[=OUTFILE]", String,
           "File name for redirected program output:",
           "  Recommended for Linux/Unix and Windows",
           "  (instead of than >-redirection).",
           "  Required for VMS, as DCL doesn't recognize",
           "  '>' as output redirection." ) do |val|
    if val
      options[:output] = val
    else
      STDERR.puts "%#{PROGNAME}-e-nooutput, specify a message digest output file"
      exit false
    end
  end  # -o --output
  opts.on( "-c", "--check",
           "Cross-check message-digest(s) from file(s);",
          "   for this option, file1 [file2]... must",
          "   be message-digest output files" ) do |val|
    options[:check] = true
  end  # -c --check
  opts.on( "--instructions", "--man",
           "Display extended instructions for #{PROGNAME}" ) do |val|
    options[:instructions] = true
    display_instructions
    exit true
  end  # --instructions

  opts.separator "\n#{VMSONLY_BORDER}"
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

if options[:output]
  options[:output] = output_ext_from_digest( options )
  $stdout = File.open( options[:output], 'w' )
end  # if options[:output]
if options[:verbose]
 STDERR.puts "%#{PROGNAME}-i-digest, message digest is \"#{options[:digest]}\""
 STDERR.puts "%#{PROGNAME}-i-mdfile, message digest file is \"#{options[:output]}\""
end

if ARGV.length > 0
  if options[:check]  # check existing *.mdigest file against actual source file(s) --
    check_files( ARGV, options )
  else  # generate "msgdigest  filename" output(s), which can be redirected --
    digest_files( ARGV, options )
  end
else
  $stdout.puts USAGE_MSG
end

exit true
