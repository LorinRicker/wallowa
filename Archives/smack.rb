#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# smack.rb
#
# Copyright © 2012 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.1 (04/14/2012)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'Prompted'

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
  opts.banner = "Usage: #{PROGNAME} [options] [ . | ... | directory | directory... ]"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
  end  # -a --about
  opts.on( "-t", "--test", "Test (rehearse) the kill" ) do |val|
    options[:test] = true
  end  # -b --test
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

ARGV.each do | pgm |
  pgmpat = Regexp.new( pgm, Regexp::IGNORECASE )
  showproc = %x{ ps aux }
  showproc.each_line do | p |

    # Match process-line for requested program, but
    #  not the line that invoked *this* program!
    if ! p.index( $0 )    # and_then
      if pgmpat =~ p      # program-pattern matched in current line?
        puts "\n#{p}"     # display it...
        pid = p.split[1]  # ...process-id is 2nd field

        if askprompted( "Kill this process #{pid}", "N" )

          if options[:test]  # rehearse...
            puts ">>> kill -kill #{pid}"
          else  # really do it... equiv -> %x{ kill -kill #{pid} }
            Process.kill( :KILL, pid.to_i )
          end  # if options[:test]

        end  # if askprompted
      end  # if p.index( pgm )
    end  # if ! p.index( !0 )
  end  # showproc.each
end  # ARGV.each
