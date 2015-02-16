#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# autoinstall.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# ========================================================================
# Single dependency: That there be a system-wide installation of a Ruby,
#                    e.g., /usr/bin/ruby2.x
#
#  $ sudo apt-get install ruby[2.x]
#
# Because the typical full-installation use case is
#  $ sudo /.../autoinstall ...
# a developer's private RVM installation does not work well.
# ========================================================================

# =================================================
# Program Description is at end-of-file (this one).
# =================================================

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.2 (02/16/2015)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'pp'
require 'fileutils'
require_relative 'lib/dpkg_utils'
require_relative 'lib/ANSIseq'
require_relative 'lib/StringEnhancements'
require_relative 'lib/TimeEnhancements'
require_relative 'lib/AskPrompted'

# Meta-characters in the Package Installation File (PIF):
COMMENTSYM = '#'
  FIELDSYM = ';'

SESSION_SEP = "=" * 60 + "\n"
INSTALL_SEP = "-" * 20 + "\n"

# ==========

def versioned_name( fil, ver )
  path = File.dirname( fil )
  ext  = File.extname( fil )
  base = File.basename( fil, ext )
  filb = File.join( path, "#{base}.#{ver}#{ext}" )
  return filb
end  # versioned_name

def roll_log( logf, options )
  if File.exists?( logf )
    vers = '001'
    logb = versioned_name( logf, vers )
    while File.exists?( logb ) && vers <= '999'
      logb = versioned_name( logf, vers.succ! )
    end  # while
    if (1..999).include?( vers.to_i )
      File.rename( logf, logb )
      STDOUT.puts "%#{PROGNAME}-I-RENAME, log file renamed to '#{logb}'" if options[:verbose]
    else
      STDOUT.puts "%#{PROGNAME}-F-LIMIT, log file version '#{vers}' exceeds range 001..999;"
      STDOUT.puts "  '#{logf}' not renamed."
      STDOUT.puts "  Move '#{versioned_name(logf,"*")}' files and retry..."
      exit false
    end
  end
end  # roll_log

def aptgetinstall( logoutf, package, ask, ppa, inq, options )
  cmd = "apt-get install --yes #{package} 2>&1"
  if ask
    prompt = "Install #{package.bold}"
    prompt = prompt + " (#{inq.to_s.bold})" if inq != ""
    do_it  = askprompted( prompt, "No" )
  else
    do_it = true
  end
  if do_it
    install_start = Time.now
    logoutf.puts "\n#{INSTALL_SEP}  ...installing #{package}\n  package-start timestamp: #{install_start}\n"
    STDOUT.puts "  ...installing #{package.underline}" if options[:verbose]
    if options[:dryrun]
      STDOUT.puts  "  #{PROGNAME}] $ #{cmd.bold}"
      logoutf.puts "  #{PROGNAME}] $ #{cmd}"
      instout = "#{' '*17}... # dry-run"
    else
      instout = %x{ #{cmd} }         # executed only as sudo/root
    end
    install_end  = Time.now
    instout.lines do | ln |
      STDOUT.puts ln if options[:debug]
      logoutf.puts ln   # echo all install-output lines to log file
    end  # this_install.lines
    logoutf.puts "  package-end timestamp: #{install_end}"
    logoutf.puts "#{' '*11}elapsed time: #{ install_start.elapsed( install_end ) }"
  end
end  # aptgetinstall

# ==========

# Default PIF is whatever's found in current working directory:
defpif = Dir.glob("./Package Installation*.list").first ||
         "./Package Installation.list"

options = { :pif      => "#{defpif}",
            :logf     => "",
            :rollover => nil,
            :yes      => nil,
            :testonly => nil,
            :echoonly => nil,
            :dryrun   => nil,
            :verbose  => nil,
            :debug    => DBGLVL0,
            :about    => nil
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-p", "--pif", "--packagefile", "=PIF",
                 "Path to Package Installation File (PIF),",
                 "  defaults to '#{defpif}'" ) do |val|
    options[:pif] = val
  end  # -p --packagefile
  opts.on( "-l", "--logfile", "=LOGF",
                 "Log file for installation trace-output;",
                 "  if this option is not specified, the log file",
                 "  defaults to PIF path and filename with '.log'" ) do |val|
    options[:logf] = val
  end  # -l --logfile
  opts.on( "-r", "--rollover", "--resetlog",
                 "Resets (rolls-over) the current log file;",
                 "  renames any current log file to '*.{001..999}.log'",
                 "  and reopens a new, start-over log file" ) do |val|
    options[:rollover] = true
  end  # -r --rollover
  opts.on( "-y", "--yes", "--forceyes",
                 "Forces a 'Yes' response to any PIF 'ask'-prompts" ) do |val|
    options[:yes] = true
  end  # -y --yes
  opts.on( "-t", "--testonly",
                 "Test and report installed/uninstalled packages" ) do |val|
    options[:testonly] = true
  end  # -t --testonly
  opts.on( "-e", "--echoonly",
                 "Echo the parsed-PIF data only (no other actions)" ) do |val|
    options[:echoonly] = true
  end  # -e --echoonly
  # --- DryRun option ---
  opts.on( "-n", "--dryrun", "Dry run: don't actually install,",
                 "  just show what would be installed" ) do |val|
    options[:dryrun] = true
  end  # -n --dryrun
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
    exit true
  end  # -a --about
  # --- Set the banner & Help options ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] ['package' ['package']...]" +
                "\n\n   where each 'package' is a PIF-line: 'package [;flags] [;ppa] [;inquiry-comment]'" +
                "\n   (usually single-quoted to avoid globbing, use special characters, etc.)\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

# Propagate a couple of implications --
options[:verbose] ||= options[:dryrun]  # ...and also debug...
options[:verbose] ||= options[:debug]   # ...and debug implies verbose
## pp options if options[:debug]

# Expand and deconstruct PIF for inheritances/defaults:
pif     = File.expand_path( options[:pif] )
pifdir  = File.dirname( pif )
pifext  = File.extname( pif )
pifbase = File.basename( pif, pifext )
## puts "pif: #{pif}"

# Unless specified by options[:logf],
#  logfile inherits /...path/filename from PIF:
logf = options[:logf] == "" ? File.join( pifdir, "#{pifbase}.log" ) : options[:logf]
logf = logf + ".log" if File.extname( logf ) == ""
logf = File.join( pifdir, logf ) if File.dirname( logf ) == "."

## STDOUT.puts " pif: '#{pif}'" if options[:debug]
## STDOUT.puts " dir: '#{pifdir}'\nbase: '#{pifbase}'\n ext: '#{pifext}'" if options[:debug]
## STDOUT.puts "logf: '#{logf}'" if options[:debug]

# Test: Unless dry-running, must be running as 'root' (sudo), else exit!
begin
  STDOUT.puts "%#{PROGNAME}-E-PRIV, only an administrator (sudoer or root) may install packages;"
  STDOUT.puts "#{" "*21}if you are an admin, prefix this command with 'sudo'..."
  exit true
end unless options[:dryrun] || ( Process.uid == 0 && Process.gid == 0 )

# If options[:rollover] then rename existing log file to *.{001..999}.log
# and allow File.open( logf, "a" ) to create a new/fresh log file
roll_log( logf, options ) if options[:rollover]

# If options[:yes] then do not askprompt (of user) for "ask"-installs,
#   just do (force) them...
# If options[:testonly] then do not actually install any packages,
#   just report whether each packages is installed or not...
#
# Open LogFile for message and apt-get install output lines
# Open PIFile for input
# For each non-blank, non-comment line:
#   Split line into (3) fields on ";"
#   Test "package" for installed-status
#   if options[:testonly]
#     then test-report ("installed" or "not installed")
#     else if "package" not installed:
#       if "ppa" is specified, test and apt-get add it
#       apt-get install "package", with "ask" or options[:yes] if specified

# Always "a"ppend the log-file:
File.open( logf, "a" ) do | logoutf |
  # Session-header (useful for multi-session appends):
  session_start = Time.now
  logoutf.puts "#{SESSION_SEP}  #{PROGID}\n  session-start timestamp: #{session_start}\n#{SESSION_SEP}"

  if ! ARGV[0]   # No command-line parameters? Then use the PIF...

    File.open( pif, "r" ) do | inf |
      inf.lines do | ln |

        package, flags, ppa, inqcomment = Array.new( 4, "" )  # start sane each interation

        # Compress whitespace, trim off (ignore) comment:
        pifline = ln.compress.split(COMMENTSYM)
        pifline = pifline.empty? ? "" : pifline[0]
        next if pifline.empty?

        STDOUT.puts ">>   pifline: '#{pifline}'" if options[:debug]
        package, flags, ppa, inqcomment = pifline.split(FIELDSYM).each { |fld| fld.strip! }
        break if package == '[EXIT]'    # An early-out, mostly for testing
        # Does "ask" appear in flags, and does options[:yes] override it?
        ask = ( flags =~ /ask/i ) || options[:yes] ? true : false    # want a real Boolean here!

        if options[:echoonly]
          STDOUT.puts "  package: '#{package}'"
          STDOUT.puts "    flags: '#{flags}'"
          STDOUT.puts "      ppa: '#{ppa}'"
          STDOUT.puts "      inq: '#{inqcomment}'"
          next   # Echoing, so just output the parsed PIFline-data... next line...
        end

        # Is this package not-yet-installed? If so, install it,
        # otherwise, report it as previously installed:
        installed = package_installed?( package )
        if not installed       # so crank it in...
          aptgetinstall( logoutf, package, ask, ppa, inqcomment, options )
        else
          msg = "Installed (#{installed}) --> #{package} is already installed"
          STDOUT.puts msg if options[:verbose]
          logoutf.puts msg
        end

      end  # inf.lines
    end  # File.open inf

  else  # got command-line parameters...

    begin
      package, flags, ppa, inqcomment = Array.new( 4, "" )  # start sane each interation
      param = ARGV.shift
      package, flags, ppa, inqcomment = param.split(FIELDSYM).each { |fld| fld.strip! }
      if not package_installed?( package )
        aptgetinstall( logoutf, package, false, ppa, inqcomment, options )
      else
        STDOUT.puts "Installed --> #{package} is already installed"
      end
    end while ARGV[0]

  end  # ! ARGV[0] ...No command-line parameters?

  # Session-footer:
  session_end = Time.now
  logoutf.puts "\n#{SESSION_SEP}  session-end timestamp: #{session_end}"
  logoutf.puts "#{' '*11}elapsed time: #{ session_start.elapsed( session_end ) }\n#{SESSION_SEP}"

end  # File.open logoutf

# =============
#  Description: Package installation on most Linux systems, certainly on Debian-
#  derived like Ubuntu and Mint, is a one-at-a-time affair, like this:
#
#      $ sudo apt-get install foobar
#      $ sudo apt-get install barfoom
#      $ ... # etc...
#
#  Also, contrary to the normally sane "succeed quietly" convention of *nix,
#  package installation is a verbosely noisy thing, with lots of (mostly very
#  unhelpful) messaging.
#
#  Finally, it's an ad-hoc affair, which encourages package exploration (the
#  cost/effort to "try out" yet another software gizmo is low, just an apt-get
#  install command away), but this is at the expense of:
#
#    a) Good record keeping (now what exactly is installed on this system?)...
#    b) Repeatability, such as if/when you're faced with a(nother) from-scratch,
#       bare-metal re-installation of a Linux box (e.g., from an Ubuntu non-LTS
#       version jumping up to an LTS version)...
#    c) Duplicatability, such as making my new laptop's package configuration
#       be (nearly) the same as my desktop's...
#
#  Without a log-book (external) record of what packages are currently installed,
#  or a lot of digging through (again verbose) dpkg-query --list output, there's
#  no repeatable (and idempotent) way to reinstall "essential packages" without
#  a lot of tedium and manual effort.
#
#  (And wouldn't it be nice if dpkg-query could distinguish and sort based
#   on "things that I've installed" versus "core", "library dependencies"
#   and "installed at system/base installation"?)
#
#  This utility script, autoinstall, brings order and a solution to this problem.
#
#  Autoinstall:
#
#       i) a) Accepts a master Package Installation File (or "PIF", a simple,
#          field-oriented text file) to keep track of my (your) "essential
#          packages".  It is expected (recommended) that, as you add (and
#          decide to keep) new software packages to your desktop or laptop
#          system, you maintain a PIF for that system in anticipation of its
#          future/next Linux bare-metal re-installation.
#
#          b) Accepts one or more parameters on the command line which are
#          'install this package now' PIF data lines.
#
#      ii) Will use (read) that a PIF file to re-install all software packages
#          listed within it, or will report that particular packages are already
#          installed (the idempotent part; you can re-autoinstall without causing
#          problems).
#
#     iii) Expects to run as sudo (root/admin privileges), so a typical usage
#          would be:
#
#          $ sudo /home/lorin/bin/autoinstall --pif=/path/to/PIF.list [options]
#
#          See autoinstall --help for all options.
#
#      iv) Creates a Log File containing the verbose/noisy output from apt-get
#          install, together with start/end timestamps and elapsed times for
#          each package installation plus the overall run/session.  The log file
#          is cumulative (opened in append mode for each run), but can be rolled
#          over, saving the old log file and creating a new one (see --rollover).
#
#  A Package Installation File (PIF) is simply a text file, a manifest, which
#  follows a few simple rules of formatting:
#
#       i) a) Each package appears by distro-name on its own line, followed by
#          an optional flags field, an optional PPA (personal package archive)
#          URI, and/or an optional inquiry-comment (if present, displayed as
#          part of the ask-inquiry prompt.  The optional fields are separated
#          from each other with semicolons ";" -- for example:
#
#          agrep
#          sshfs                   ;     ; ; optional remote/SSH file-system
#          gimp                    ; ask
#          lyx                     ; ask ; ; takes A Long Time to install!
#          sublime-text-installer  ; ask ; ppa:webupd8team/sublime-text-3
#
#          b) Each (optional) command line parameter can contain the same data
#          elements as a PIF line: 'package [;flags] [;ppa] [;inquiry-comment]'
#          Each parameter is usually single-quoted to guard against unintended
#          command line (bash) globbing, misinterpretation of special characters,
#          etc. Like a PIF line, only the package name (first) field is required;
#          the flags, ppa and inquiry-comment are optional, but if present, must
#          be separated by semicolons ";" -- for example:
#
#            $ autoinstall [-options] agrep 'gimp;ask' \
#                 'sshfs;;;optional remote/SSH file-system' \
#                 'lyx;ask;;takes A Long Time to install!' \
#                 'sublime-text-editor;ask;ppa:webupd8team/sublime-text-3'
#
#      ii) Currently, the only implemented flag is "ask", which enables a prompt
#          for that package: "Install <packagename> (y/n) [No]? " ... Packages
#          which do not "ask" are installed without prompting.
#
#     iii) Comments begin with a pound-sign "#" and can either be a whole line
#          or can be the trailing element on a line.  Comments are ignored.
#
#      iv) Spacing is free-format throughout; you can document your PIF with
#          comments, blank/empty lines are permitted, and spacing between fields
#          is ignored (so you can line-up your "asks" and PPAs if you want).
#
#  Final note: Obviously, this Ruby script/program depends on Ruby (MRI, Matz's
#  Ruby Interpreter) being installed and available. Autoinstall.rb is written
#  to be as Ruby-version agnostic as possible, and it's been tested with MRI
#  versions 1.9.x and 2.x (but not with 1.8; it may work).
#
#  Since this program requires Ruby, and is intended to be (will be) run as a
#  sudo'd script, a freshly-installed Linux will likely need to do a manual Ruby
#  install:
#
#    $ sudo apt-get install ruby[1.9.1]
#
#  as a bootstrap... This puts a well-tested Ruby (well, it's in your distro's
#  repository, right?) into your system-wide toolkit (just like Python).
#
#  == RVM ===
#    Note: For Ruby development work, install Ruby using the great
#          Ruby enVironment Manager (RVM, http://rvm.io -- and see
#          http://rvm.io/rvm/install for help):
#
#          $ \curl -L https://get.rvm.io | bash -s stable
#
#          Be sure that .bashrc -> ~bin/login/bashrc contains this
#          line at its end, or execute this command interactively:
#
#            source $HOME/.rvm/scripts/rvm
#
#          Logout and then login to activate rvm commands, then
#          install Ruby version(s) of your choice:
#
#          $ rvm install 1.9.3     # Note! These Ruby installs may
#          $ rvm install 2.1       #       take 'a long time'!
#
#          Don't forget Ruby online documentation:
#
#          $ rvm docs generate-ri
#
#          Finally, set your desired Ruby version for use:
#
#          $ rvm use --default 2.1
#          $ rvm current   # to see/confirm
#  == end RVM ===
#
#  Now... after installing a system-wide Ruby, you're ready to restore (re-install)
#  software packages, typically like this:
#
#    $ sudo /home/pathto/autoinstall.rb --pif=/home/pathto/YourPIF.lis
#
#  If you're super-cautious, you can "dry-run" it first with --dryrun (-n).
#
#  To test for package installation (whether or not your packages are
#  already installed), use --testonly (-t).
#
#  To watch the parade go by -- see the packages announced as installed --
#  use --verbose (-v); for lots of debugging noise, use --debug (-d).
#
#  For unattended use, which forces/answers "Y" to any "asks", use --yes
#  (-y or --forceyes).
#
#  To override the default log file name (which is "Package Installation.log"),
#  use --logfile="LogFileName".
#
#  To "rollover" the log file (saving any previous log file and opening
#  a new one), use --rollover (-r or --resetlog).
#
#  TO-DO list:
#    0. Make PPA installs work...
#    1. Is there a pre-existing (and possibly better) utility program out there
#       in the Linux Open Source Community for autoinstalls? (No, I don't mean
#       a power-tool like Kickstarter).
#    2. Currently, autoinstall can only do "apt-get install"... possibly add
#       "apt-get remove | purge"?
#    3. Better way(s) of detecting "package is already installed" than parsing
#       output-text from "dpkg-query --show"?
#
