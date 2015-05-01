#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# dcl.rb
#
# Copyright © 2012-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# -----

    PATH = File.dirname $0
 DCLNAME = File.join( PATH, "dcl" )          # hard-wire this name...
LINKPATH = File.join( PATH, "dcllinks" )     # symlinks go here...

PROGNAME = File.basename( DCLNAME ).upcase   # not "$0" here!...
  PROGID = "#{PROGNAME} v4.0 (05/01/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

   CONFIGDIR = File.join( ENV['HOME'], ".config", PROGNAME )
  CONFIGFILE = File.join( CONFIGDIR, ".#{PROGNAME}.yaml.rc" )

# -----

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

# dcl is an emulator environment for selected VMS (OpenVMS) DCL commands
# and lexical functions. It provides a transitional working environment
# between VMS and Linux command line syntaxes, while also providing
# extended com-line lexical functions borrowed from VMS into Linux.

# dcl is extended (v2.xx) to provide DCL file operation command emulations
# for several common file commands:
# COPY:cp, DELETE:rm, RENAME:mv,
# CREATE:touch, PURGE:??, DIRECTORY:ls,
# SEARCH:grep, SHOW:set.

# dcl provides command line (shell) access to a small library of string-
# transformational routines which are reminiscent of those found in the
# VMS/DCL repertory of F$* functions, callable as if these were bash
# "built-in" functions (v1.xx).

# Access (calls) to these functions are implemented by creating named symlinks
# for each function; these symlinks point (refer to) this dcl script itself,
# such that Ruby's $0 variable (the name of the command/file reference which
# invoked this script invocation) can dispatch execution-control to the correct
# String class method.

# Input for each function comes either from:
#
#   1) The concatenation of all non-switch (non-option) arguments on the
#      command line, joined into a single space-separated string argument.
#      For example, the string-argument for: $ upcase this "is a  " test
#      is: "this is a   test"
#
#   2) Standard Input, if there is/are no non-switch options provided on
#      the command line.

# Output from the function is written to Standard Output with no further
# embellishments or decorations (i.e., no surrounding quotations, etc.).
# For example, the output from the sample upcase function call given in 1)
# above would be: THIS IS A   TEST

# The --verbose (-v) option is for testing &/or verification of input/output
# results: thus this command will output three lines, the echoed command line,
# the annotated result, and the pure result line itself:
#
#   $ upcase -v "this is a test"
#   %upcase-I-echo,   $ upcase 'this is a test'
#   %upcase-I-result, 'THIS IS A TEST'
#   THIS IS A TEST

# Function results can be captured/assigned to a bash variable thusly:
#
#   $ var=$( upcase "this is a test" )
#   $ echo $var
#   THIS IS A TEST

# This mechanism also provides for functional results to be applied via a pipe:
#
#   $ var=$( compress "  this   is a test   " | upcase )
#   $ echo $var
#   THIS IS A TEST

# Intermediate results can be checked/tracked with --verbose:
#
#   var=$( compress -v "   this is a      test   " | upcase -v )
#   %compress-I-echo,   $ compress '   this is a      test   '
#   %compress-I-result, 'this is a test'
#   %upcase-I-echo,   $ upcase 'this is a test'
#   %upcase-I-result, 'THIS IS A TEST'
#   $ echo $var
#   THIS IS A TEST

# One function, edit, allows a list of edits to be applied to the argument
# string, which is an alternative way to the pipe-method above to execute
# a sequence of functional filters:
#
#   $ edit -v "compress,upcase" "   this is a      test   "
#   %dcl-I-echo,   $ edit '   this is a      test   '
#   %dcl-I-result, 'THIS IS A TEST'
#   THIS IS A TEST

# One dcl function is special: dclsymlink -- This function checks and verifies
# each of its arguments, which name function symlink(s): it does for each named
# function(s) what the --symlinks option (below) does for all functions.
#
#   $ dclsymlink capcase locase [...]
#   %dcl-S-created, symlink ~/bin/dcllinks/capcase created
#   %dcl-S-created, symlink ~/bin/dcllinks/locase created

# The --symlinks (-s) option checks &/or verifies each function in FNC_LINKS
# (including itself), and either creates a symlink to the dcl script if it does
# not (yet) exist, or complains with an error message if a previous (ordinary)
# file by that name already exists.
#
# The dcl --symlinks option serves as an installation bootstrap step, as well
# as a periodic &/or troubleshooting verification step; e.g.:
#
#   $ dcl [--verbose] --symlinks   # verify &/or install all function symlinks
#   %dcl-S-created, symlink ~/bin/dcllinks/capcase created
#   %dcl-S-verified, symlink ~/bin/dcllinks/collapse verified
#   %dcl-S-verified, symlink ~/bin/dcllinks/compress verified
#   ...
#   %dcl-S-created, symlink ~/bin/dclsymlink created

require 'optparse'
require 'fileutils'
require 'pp'
require_relative 'lib/ppstrnum'
require_relative 'lib/StringEnhancements'
require_relative 'lib/FileEnhancements'
require_relative 'lib/ANSIseq'

# ==========

def bad_fucmd_params( e, debug, errmsg = "notdir, destination path must be a directory" )
  $stderr.puts "%#{PROGNAME}-e-#{errmsg}"
  pp e if debug > DBGLVL0
  exit false
end  # bad_fucmd_params

def help_available( tag, links, perline )
  hlp    = tag
  hlplen = hlp.length
  i      = 0
  links.each do | c |  # concatenate c ,-sep & measured list of commands
    i   += 1
    hlp += c
    hlp += ", " if i < links.size
    hlp += "\n" + " "*hlplen if i % perline == 0 && i < links.size
  end  # links.each
  puts "\n#{hlp}"
end  # help_available

# ==========

def parse_dcl_qualifiers( argvector )
  dcloptions = Hash.new
  fspecs     = []
  pat        = /^\/(LOG|CON[FIRM]*|PAG[E]*)$/i
  argvl      = argvector.length
  argvector.each do | a |
    if pat.match( a )
      # A DCL qualifier /LOG or /CON[FIRM] or /PAG[E]: record it...
      case $1[0..2].downcase
      when 'log' then dcloptions[:verbose] = true
      when 'con' then dcloptions[:confirm] = true
      when 'pag' then dcloptions[:pager]   = true
      end  # case
    else
      # A file-spec, copy it...
      fspecs << a
    end
  end
  return case argvl
         when 0 then [ nil,           nil,        dcloptions ]
         when 1 then [ [ fspecs[0] ], nil,        dcloptions ]
         when 2 then [ [ fspecs[0] ], fspecs[1],  dcloptions ]
                else [ fspecs[0..-2], fspecs[-1], dcloptions ]
         end  # case
end  # parse_dcl_qualifiers

def blend( options, dcloptions )
  opts = Hash.new
  opts[:verbose]  = options[:verbose] || dcloptions[:verbose]
  opts[:page]     = options[:page]    || dcloptions[:page]
  opts[:preserve] = options[:preserve]
  opts[:noop]     = options[:noop]
  return opts
end  # blend

# ==========

def dclCommand( action, operands, options )
  src, dst, dcloptions = parse_dcl_qualifiers( operands )
  alloptions = blend( options, dcloptions )
  begin
    pp( src, $stdout )
    pp( dst, $stdout )
    pp( dcloptions, $stdout )
    pp( alloptions, $stdout )
  end if options[:debug] >= DBGLVL2

  # Commands:
  case action.to_sym              # Dispatch the command-line action;
                                  # invoking symlink's name is $0 ...
  when :copy
    # See ri FileUtils[::cp]
    begin
      FileUtils.cp( src, dst, alloptions )
    rescue StandardError => e
      bad_fucmd_params( e, options[:debug] )
    end
  # when :create
  when :rename
    # See ri FileUtils[::mv]
    ## see rename.rb -- may just exec() this here ???
    ## begin
    ##   FileUtils.mv( src, dst, alloptions )
    ## rescue StandardError => e
    ##   bad_fucmd_params( e, options[:debug] )
    ## end
    cmdRename( operands, options )
  when :delete
    # See ri FileUtils[::rm]
    begin
      FileUtils.rm( src, alloptions )
    rescue StandardError => e
      bad_fucmd_params( e, options[:debug] )
    end
  # when :purge
  # when :directory
  # when :show
  when :search
  # 'SEARCH files pattern' --> 'grep pattern files'
  # This 'SEARCH' command is more powerful than VMS/DCL's, since it uses
  # general regular expressions (regexps) rather than 'simple wildcarded'
  # search-strings...
    cmd = "/bin/grep --color=always --ignore-case -e '#{dst}' "
    src.each { |s| cmd << " '#{s}'" }
    # for less, honor grep's color output with --raw-control-chars:
    cmd += " | /bin/less --raw-control-chars" if options[:pager] or alloptions[:pager]
    exec( cmd )  # chains, no return...
  else
    $stderr.puts "%#{PROGNAME}-e-nyi, DCL command '#{action}' not yet implemented"
    exit false
  end  # case action.to_sym

end  # dclCommand

# ==========

def getOps( operands, options )
  ops = ''
  if operands[0]
    ops = operands.join( " " )           # All operands into one big sentence...
  else                                   # ...or from std-input
    ops = $stdin.readline.chomp if !options[:symlinks]
  end  # if operands[0]
  return ops
end  # getOps

def dclFunction( action, operands, options )
  # Functions:
  case action.to_sym              # Dispatch the command-line action;
                                  # invoking symlink's name is $0 ...
  when :capcase
    ops = getOps( operands, options )
    result = ops.capcase

  when :collapse
    ops = getOps( operands, options )
    result = ops.collapse

  when :compress
    ops = getOps( operands, options )
    result = ops.compress

  when :length
    ops = getOps( operands, options )
    result = ops.length         # String class does this one directly

  when :locase
    ops = getOps( operands, options )
    result = ops.locase         # String class does this one directly

  when :numbernames
    # $ numbernames number
    ops = getOps( operands, options )
    # Stanza-per-line output:
    #    call as: ops.numbernames( '\n' )
    # for use as: $ echo -e $( numbernames <num> )
    result = ops.numbernames.split( ', ' )
    result.each { |s| $stdout.puts s }
    exit true

  when :thousands
    # $ thousands number
    ops = getOps( operands, options )
    result = ops.thousands

  when :titlecase
    ops = getOps( operands, options )
    result = ops.titlecase

  when :trim
    ops = getOps( operands, options )
    result = ops.strip          # String class does this one directly

  when :trim_leading
    ops = getOps( operands, options )
    result = ops.lstrip         # String class does this one directly

  when :trim_trailing
    ops = getOps( operands, options )
    result = ops.rstrip         # String class does this one directly

  when :uncomment
    ops = getOps( operands, options )
    result = ops.uncomment

  when :upcase
    ops = getOps( operands, options )
    result = ops.upcase         # String class does this one directly

  # when :«+»
  #   ops = getOps( operands, options )
  #   result = ops.«+»

  when :cjust
    # $ cjust width "String to center-justify..."
    ## >> How to default width to terminal-width, and how to specify padchr? Syntax?
    width  = ops.shift.to_i
    # padchr = ops.shift
    ops = getOps( operands, options )
    result = ops.center( width )

  when :ljust
    # $ ljust width "String to center-justify..."
    width  = ops.shift.to_i
    # padchr = ops.shift
    ops = getOps( operands, options )
    result = ops.ljust( width )

  when :rjust
    # $ rjust width "String to center-justify..."
    width  = ops.shift.to_i
    # padchr = ops.shift
    ops = getOps( operands, options )
    result = ops.rjust( width )

  when :edit
    # $ edit "func1,func2[,...]" "String to filter"
    #   where "func1,funct2[,...]" -- the editlist -- is required
    editlist = ops.shift            # assign and remove arg [0]
    ops = getOps( operands, options )
    result = ops.edit( editlist, '#' )  # assume bash-style comments

  when :element
    # $ element 2 [","] "String,to,extract,an,element,from:
    #   where first arg is the element-number (zero-based) to extract,
    #   and second arg is (optional) element separator (default ",");
    #   note that if length of second arg is > 1, it defaults, and
    #   remainder of string is the string to filter
    elem = ops.shift.to_i           # assign and remove arg [0]
    sep  = ops[0].length == 1 ? ops.shift : ","  # and arg [1]
    ops = getOps( operands, options )
    result = ops.element( elem, sep )

  when :pluralize
    # $ pluralize word howmany [irregular]
    word      = ops.shift                  # assign and remove arg [0]
    howmany   = ops.shift.to_i             # and arg [1]
    irregular = ops[0] ? ops.shift : nil  # and (optional) arg [2]
    # ops = getOps( operands, options )             # ...ignore rest of com-line
    result = word.pluralize( howmany, irregular )

  when :substr, :extract
    # $ substr start len "String to extract/substring from..."
    start = ops.shift.to_i
    len   = ops.shift.to_i
    ops  = getOps( operands, options )
    result = ops[start,len]      # String class does this one directly

  when :dclsymlink
    # $ dclsymlink action [action]...
    dclsymlink( ops )            # Set &/or verify this action verb symlink
    exit true

  else
    $stderr.puts "%#{PROGNAME}-e-nyi, DCL function '#{action}' not yet implemented"
    exit false

  end  # case action.to_sym

  if options[:verbose]
    $stderr.puts "%#{PROGNAME}-I-echo,   $ " + "#{action}".underline + " '#{ops}'"
    $stderr.puts "%#{PROGNAME}-I-result, " + "'#{result}'".bold
  end  # if options[:verbose]

  $stdout.print result  # Print filtered result to std-output

end  # dclFunction

# ==========

def dclSymlink( syms )
  dn = "-> #{DCLNAME}"
  FileUtils.mkdir_p( LINKPATH ) if ! File.exists?( LINKPATH )
  syms.each do |s|
    slnk = File.join( LINKPATH, s )
    if File.symlink?( slnk )
      # See http://ruby.runpaint.org/ref/file for documentation of new methods
      # File.readlink (used here) and File.realpath...
      if File.readlink( slnk ) == DCLNAME
        $stderr.puts "%#{PROGNAME}-I-verified, symlink #{slnk} is verified (#{dn})".color(:green)
      else
        $stderr.puts "%#{PROGNAME}-E-badlink,  symlink #{slnk} is wrong (not #{dn})".color(:red)
      end  # if File.identical?( DCLNAME, slnk )
    else
      if ! File.file?( slnk )  # no ordinary file collision?
        File.symlink( DCLNAME, slnk )
        $stderr.puts "%#{PROGNAME}-S-created,  symlink #{slnk} created (#{dn})".color(:blue)
      else
        $stderr.puts "%#{PROGNAME}-E-conflict, file #{slnk} exists, no symlink created".color(:red)
      end  # if ! File.file?( slnk )
    end  # if File.symlink( slnk )
  end  # syms.each
end  # dclSymlink

# ==========

                # See also dclrename.rb; "set" conflicts with bash 'set' command
CMD_LINKS = %w{ copy create rename
                delete purge search
                directory show }
FNC_LINKS = %w{ capcase locase upcase titlecase
                collapse compress
                cjust ljust rjust
                edit element extract substr
                length pluralize
                thousands numbernames
                trim trim_leading trim_trailing
                uncomment
                dclsymlink }
ALL_LINKS = CMD_LINKS + FNC_LINKS

options = { :interactive => false,
            :noop        => false,
            :pager       => false,
            :preserve    => false,
            :links       => false,
            :verbose     => false,
            :debug       => DBGLVL0,
            :about       => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
  opts.on( "-i", "--interactive", "--confirm",
           "Interactive mode (/CONFIRM)" ) do |val|
    options[:interactive] = true
  end  # -i --interactive
  opts.on( "-m", "--pager", "--less", "--more",
           "Use pager (less) for long output" ) do |val|
    options[:pager] = true
  end  # -m --pager
  opts.on( "-p", "--preserve",
           "Preserves file metadata (owner, permissions, datetimes)" ) do |val|
    options[:preserve] = true
  end  # -p --preserve
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
  opts.on( "-l", "--links", "--symlinks",
           "Create or verify symlinks for all functions" ) do |val|
    options[:symlinks] = true
  end  # -l --symlinks --links
  # --- About option ---
  opts.on_tail( "-a", "--about", "Display program info" ) do |val|
    $stdout.puts "#{PROGID}"
    $stdout.puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] dclfunction"   +
                "\n\n   where dclfunction is the DCL command or lexical function to execute.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    help_available( '  Available commands: ', CMD_LINKS, 8 )
    help_available( ' Available functions: ', FNC_LINKS, 6 )
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

## File.check_yaml_dir( CONFIGDIR )
## File.configuration_yaml( «+», «+» )

action = File.basename( $0 ).downcase  # $0 is name of invoking symlink...

if options[:symlinks]
  dclSymlink( ALL_LINKS )       # set &/or verify ALL_LINKS symlinks
else
  # Dispatch/processing for each sym-linked command begins here...
  if CMD_LINKS.find( action )   # one of the Command actions?
  then
    dclCommand( action, ARGV, options )
  else
    dclFunction( action, ARGV, options )
  end
end  # if options[:symlinks]

exit true
