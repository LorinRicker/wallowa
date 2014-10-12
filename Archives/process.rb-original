#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# process.rb
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.3 (10/22/2012)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require_relative 'Prompted'
require_relative 'TermChar'
require_relative 'ANSIseq'

# Main -- a really simple script to perform a prompted-kill-process,
#         "$ ps aux | grep [f]oobar" -- where the "...grep [p]attern"
#         trick with the brackets [] sidesteps finding the ps|grep
#         command itself... This does the same thing by *not* finding
#         the process which invokes this command:

options = {}  # hash for all com-line options;
  # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
  # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
  # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] [ process-id-string | ... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
  end  # -a --about
  opts.on( "-k", "--kill", "Kill a process" ) do |val|
    options[:kill] = true
  end  # -k --kill
  opts.on( "-r", "--raw", "Raw output (no header, no footer)" ) do |val|
    options[:raw] = true
  end  # -r --raw
  opts.on( "-t", "--test", "Test (rehearse) the kill" ) do |val|
    options[:test] = true
  end  # -t --test
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

# Customize the output of ps -- note that pid is now FIRST field! --
ps_options = '-e --format pid,euser,%cpu,%mem,rss,stat,args'

# Set-up ps for terminal dimensions, especially varying width:
termwidth = TermChar.terminal_dimensions( options[:verbose] )
twidth = "--width #{termwidth[1]}"

ARGV.each do | pgm |
  pgmpat = Regexp.new( pgm, Regexp::IGNORECASE )
  showproc = %x{ ps #{ps_options} #{twidth} }
  lno = pcnt = 0
  showproc.each_line do | p |
    lno += 1
    if lno > 1
      # Match process-line for requested program, but
      #  not the line that invoked *this* program!
      if ! p.index( $0 )    # and_then
        if pgmpat =~ p      # program-pattern matched in current line?
          puts "#{p}"       # display it & count it...
          pcnt += 1
          pid = p.split[0]  # process-id is FIRST field...
                            # ...see ps_options above
          if options[:kill]
            if askprompted( "Kill this process #{pid}", "N" )
              if options[:test]  # rehearse...
                puts ">>> kill -kill #{pid}"
              else  # really do it... equiv -> %x{ kill -kill #{pid} }
                Process.kill( :KILL, pid.to_i )
                puts ""
              end  # if options[:test]
            end  # if askprompted
          end  # if options[:kill]

        end  # if pgmpat =~ p
      end  # if ! p.index( !0 )
    elsif not options[:raw]  # print the ps-header
      q = p.chomp + ' ' * ( termwidth[1] - p.length )
      printf "\n%s\n".bold.underline, q
    end  # if lno > 1
  end  # showproc.each
  puts "\nProcess count: #{pcnt}" unless options[:raw]
end  # ARGV.each
