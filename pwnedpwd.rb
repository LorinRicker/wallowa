#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# pwnedPassword.rb
#
# Copyright © 2018 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Based on this article and corresponding Gem
# https://www.twilio.com/blog/2018/03/better-passwords-in-ruby-applications-pwned-passwords-api.html
#
# In 2017 NIST (National Institute of Standards and Technology) as part of their
# revised digital identity guidelines recommended that user passwords are checked
# against existing public breaches of data.
#
# The idea is that if a password has appeared in a data breach before then it
# is deemed compromised and should not be used.
#
# This little program submits the password(s) on the command line (ARGV) to
# pwned-check to see if the pwd(s) has/have been compromised.
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.1 (03/27/2018)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

# For pwned documentation, see https://github.com/philnash/pwned
require 'pwned'     # gem install pwned

require 'optparse'  # standard library
require_relative 'lib/ppstrnum'
require_relative 'lib/GetPrompted'

def check_password( arg )
  pwd = Pwned::Password.new( arg )
  if pwd.pwned?
    pwdpwnedcount = pwd.pwned_count.thousands
    plural = pwdpwnedcount != 1 ? "s" : ""
    puts "\nPassword '#{arg}' has been stolen and compromised #{pwdpwnedcount} time#{plural}" +
         " -- do not use it!"
  else
    hidepwd = arg[0..1] + ( '·' * (arg.length-2) )
    puts "\nPassword '#{hidepwd}' has not been pwned"
  end
end # check_password

# === Main ===
options = { :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
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
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] password1 [password2]..." +
                "\n\n   where the passwords are candidates to check against the Pwned database\n\n"
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

if ARGV.count > 0
  ARGV.each do | arg |
    check_password( arg )
  end
else
  while arg = getprompted( "\npwd", "" )
    break if arg == ""
    check_password( arg )
  end  # while
end

exit true
