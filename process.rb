#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# process.rb
#
# Copyright © 2012-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v4.00 (05/17/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

# A really simple script to perform a prompted-kill-process,
# "$ ps aux | grep [f]oobar" -- where the "...grep [p]attern"
# trick with the brackets [] sidesteps finding the ps|grep
# command itself... This does the same thing by *not* finding
# the process which invokes this command:

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

require 'optparse'
require 'pp'
require_relative 'lib/Prompted'
require_relative 'lib/WhichOS'
require_relative 'lib/TermChar'
require_relative 'lib/ANSIseq'

# ==========

def abort( os )
  # Not yet supporting Unix(es), Darwin (Mac), Windoze, etc:
  STDERR.puts "%#{PROGNAME}-f-nosupp, operating system '#{os}' is not yet supported"
  exit false
end  # abort( os )

def generate_command( options, twidth )
  case options[:os]
  when :linux
    # Customize the output of ps -- note that pid is now first field! --
    psopt = '-e --format pid,euser,%cpu,%mem,rss,stat,args'
    cmd   = [ 1, "ps #{psopt} --width #{twidth}" ]
  when :vms
    # Note that pid is always first, and this listing is not customizable --
    cmd   = [ 2, 'SHOW SYSTEM /CLUSTER' ]
  else
    abort( options[:os] )
  end
  STDERR.puts "%#{PROGNAME}-i-cmd, `#{cmd[1]}`" if options[:debug] >= DBGLVL1
  return cmd
end  # generate_command

def kill_it( pid, options )
  if askprompted( "Kill this process #{pid}", "N" )
    if options[:test]  # rehearse for the right platform...
      case options[:platform]
      when :linux
        STDERR.puts ">>> $ kill -s #{options[:signal]} #{pid}".color(:red).bold
      when :vms
        STDERR.puts ">>> $ STOP /ID=#{pid}".color(:red).bold
      end
    else  # really do it... equiv -> %x{ kill -kill #{pid} }
      begin
        case options[:platform]
        when :linux
          Process.kill( options[:signal].to_sym, pid.to_i )
        when :vms
        vmscmd = %x{ STOP /ID=#{pid} }
        end
      rescue Errno::ESRCH => e  # 'No such process'
        puts "%#{PROGNAME}-w-noproc, process was previously terminated (parent process killed)"
        # continue...
      end
    end
    puts ""
  end
end  # kill_it

def process( args, options )
  options[:os] = WhichOS.identify_os
  STDERR.puts "%#{PROGNAME}-i-os, '#{options[:os]}' operating system" if options[:debug] >= DBGLVL1
  # Switch immediately to testing-mode if the identified OpSys <> the com-line requested one...
  options[:test] = true if options[:platform] && options[:platform] != options[:os]
  STDERR.puts "options: #{options}" if options[:debug] >= DBGLVL1

  # Set-up for terminal dimensions, especially varying width:
  termdim = TermChar.terminal_dimensions( options[:verbose], options[:os] )

  hdlines, command = generate_command( options, termdim[1] )
  lno = pcount = acount = 0

  args.each do | pgm |
    acount += 1
    pgmpat = Regexp.new( pgm, Regexp::IGNORECASE )
    puts "  >>> `#{command}`" if options[:debug] >= DBGLVL1
    %x{ #{command} }.lines do | p |
      lno += 1
      if lno > hdlines
        # Match process-line for requested program, but
        #  not the line that invoked *this* program!
        if ! p.index( $0 )    # and_then
          if pgmpat =~ p      # program-pattern matched in current line?
            STDOUT.puts p     # display it & count it...
            pcount += 1
            pid = p.split[0]  # process-id is FIRST field...
            kill_it( pid, options ) if options[:kill]
          end
        end
      elsif not options[:raw]         # Print the ps-header,
        STDOUT.puts "" if lno == 1    # preceeded by one blank line
        if lno == hdlines
          # Underline the last header line, extending underline to right-margin:
          q = p.chomp + ' ' * ( termdim[1] - p.length + 1 )
          STDOUT.puts q.bold.underline
        else
          # just echo the header line:
          STDOUT.puts p.chomp.bold
        end
      end
    end
    if acount == args.size
      STDOUT.puts "\nProcess count: #{pcount}" unless options[:raw]
    end
  end  # args.each

end  # process

# ==========

options = { :signal   => "KILL",
            :platform => nil,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-k", "--kill", "Kill a process" ) do |val|
    options[:kill] = true
  end  # -k --kill
  opts.on( "-p", "--platform=OpSys", "--opsys",
           "Operating system platform (for testing)" ) do |val|
    options[:platform] = val.downcase.to_sym
  end  # -p --platform
  opts.on( "-r", "--raw", "Raw output (no header, no footer)" ) do |val|
    options[:raw] = true
  end  # -r --raw
  opts.on( "-s", "--signal[=#{options[:signal]}]",
           "Process termination signal (default = #{options[:signal]})" ) do |val|
    options[:signal] = val.upcase
  end  # -s --signal
  opts.on( "-t", "--test", "Test (rehearse) the kill" ) do |val|
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
  opts.banner = "\n  Usage: #{PROGNAME} [options] [ process-id-string | ... ]" +
                "\n\n   where process-id-string is any character string to"    +
                "\n   identify one or more processes to display and/or kill.\n\n"
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

pp options
process( ARGV, options )
