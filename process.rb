#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# process.rb
#
# Copyright © 2012-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v2.3 (10/15/2012)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# A really simple script to perform a prompted-kill-process,
# "$ ps aux | grep [f]oobar" -- where the "...grep [p]attern"
# trick with the brackets [] sidesteps finding the ps|grep
# command itself... This does the same thing by *not* finding
# the process which invokes this command:

# === For command-line arguments & options parsing: ===
require 'optparse'
require 'pp'
require_relative 'lib/Prompted'
require_relative 'lib/TermChar'
require_relative 'lib/ANSIseq'

# ==========

def abort( os )
  # Not yet supporting Unix(es), Darwin (Mac), Windoze, etc:
  STDERR.puts "%#{PROGNAME}-f-nosupp, operating system '#{os}' is not yet supported"
  exit false
end  # abort( os )

def identify_os
  begin
    whichos = RUBY_PLATFORM  # s'posed to exist, but might not for some Rubies
  rescue NameError => e
    require 'rbconfig'
    whichos = RbConfig::CONFIG['host_os']
  ensure
    case whichos.downcase
    when /linux/ then return :linux
    when /vms/   then return :vms
    else
      abort( whichos )
    end
  end
end  # identify_os

def generate_command( options, twidth )
  case options[:os]
  when :linux
    # Customize the output of ps -- note that pid is now first field! --
    psopt = '-e --format pid,euser,%cpu,%mem,rss,stat,args'
    cmd   = [ 1, "ps #{psopt} --width #{twidth}" ]
  when :vms
    # Note that pid is always first, and this listing is not customizable --
    cmd   = [ 2, "SHOW SYSTEM /CLUSTER" ]
  else
    abort( options[:os] )
  end
  return cmd
end  # generate_command

def kill_it( pid, options )
  if askprompted( "Kill this process #{pid}", "N" )
    if options[:test]  # rehearse for the right platform...
      case options[:platform]
      when :linux
        STDOUT.puts ">>> $ kill -s #{options[:signal]} #{pid}".color(:red).bold
      when :vms
        STDOUT.puts ">>> $ STOP /ID=#{pid}".color(:red).bold
      end
    else  # really do it... equiv -> %x{ kill -kill #{pid} }
      begin
        Process.kill( options[:signal].to_sym, pid.to_i )
        # N.B. -- Will VMS Ruby's Std-Library support Process.kill?
        #         If not, then must do %x{ STOP /ID=#{pid} }
      rescue Errno::ESRCH => e  # 'No such process'
        puts "%#{PROGNAME}-w-noproc, this process has been terminated (parent process killed)"
        # continue...
      end
    end
    puts ""
  end
end  # kill_it

def process( args, options )
  options[:os] = identify_os
  STDERR.puts "%#{PROGNAME}-i-os, '#{options[:os]}' operating system" if options[:debug]
  # Switch immediately to testing-mode if the identified OpSys <> the com-line requested one...
  options[:test] = true if options[:platform] && options[:platform] != options[:os]
  STDERR.puts "options: #{options}" if options[:debug]

  # Set-up for terminal dimensions, especially varying width:
  termdim = TermChar.terminal_dimensions( options[:verbose] )

  hdlines, command = generate_command( options, termdim[1] )
  lno = pcount = acount = 0

  args.each do | pgm |
    acount += 1
    pgmpat = Regexp.new( pgm, Regexp::IGNORECASE )
    %x{ #{command} }.each_line do | p |
      lno += 1
      if lno > hdlines
        # Match process-line for requested program, but
        #  not the line that invoked *this* program!
        if ! p.index( $0 )    # and_then
          if pgmpat =~ p      # program-pattern matched in current line?
            STDOUT.puts p     # display it & count it...
            pcount += 1
            pid = p.split[0]  # process-id is FIRST field...
            kill_it( pid, options) if options[:kill]
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

options = { signal:   "KILL",
            platform: nil,
            debug:    nil
          }

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
  opts.on( "-d", "--debug=[N]", "Turn on debugging messages (levels)" ) do |val|
    options[:debug] = val || 1
  end  # -d --debug
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] [ process-id-string | ... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
    exit true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
}.parse!  # leave residue-args in ARGV

process( ARGV, options )
