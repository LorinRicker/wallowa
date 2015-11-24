#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# purgekernel.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# purgekernel supports the automated (user-driven) removal of old Linux kernel
# packages, using a command shell to execute 'apt-get purge linux-*' for both
# kernel images and kernel headers ...
# See "$dlb/Linux/HowTos/HowTo - Remove old Linux kernel packages.txt"

# -----

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.1 (11/24/2015)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

# -----

MAGICSTR = '«·»'

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# ==========

require 'optparse'
require 'pp'
require_relative 'lib/Prompted'
require_relative 'lib/TermChar'
require_relative 'lib/ANSIseq'

# ==========

# ==========

options = { :confirm     => true,
            :lessthan    => nil,
            :greaterthan => nil,
            :noop        => nil,
            :verbose     => false,
            :debug       => DBGLVL0,
            :about       => false
          }

ARGV[0] = '--help' if ARGV.size == 0  # force help if naked command-line

optparse = OptionParser.new { |opts|
  opts.on( "-i", "--confirm", "--interactive",
           "Interactive/confirm mode" ) do |val|
    options[:confirm] = val
  end  # -n --dryrun
  opts.on( "-l", "--lessthan=DashValue", Integer,
           "Purge dash-numbers #{'less than'.bold} this value" ) do |val|
    options[:lessthan] = val.to_i
  end  # -l --lessthan
  opts.on( "-g", "--greaterthan=DashValue", Integer,
           "Purge dash-numbers #{'greater than'.bold} this value" ) do |val|
    options[:greaterthan] = val.to_i
  end  # -g --greaterthan
  opts.on( "-n", "--dryrun", "Test (rehearse) the kernel package purge" ) do |val|
    options[:noop] = true
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
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] [ kernel-ident ]" +
                "\n\n    where kernel-ident is a character string which identifies one or more" +
                "\n    #{'kernel install packages to purge'.underline}.\n\n"
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

# Each uninitialized hash-key returns an empty array --
lkpackages = Hash.new { |k,v| k[v] = [] }
lk2purge   = Hash.new { |k,v| k[v] = [] }

if options[:confirm] || ARGV.empty?
  # See man dpkg-query (watch out for automatic
  # field-width truncations under column "Name"!) --
  cmd = "dpkg-query --show --showformat='${Status} ${Package}\n' \"linux*\""
  pat = /^install\ ok\ installed\            # only Install-Installed packages
         (?<pckg>                            # full package name
         (?<pfix>linux-(image|headers)-)     # only linux* (kernel) packages
         (?<vers>\d+\.\d+\.\d+)              # MM.mm.rev version spec
         -(?<dash>\d+)                       # -dash spec
             (\.\d+)?                        # don't care: .XX
         (?<sfix>(-\w+)?)                    # "-generic" or empty
         )
        /x

  prefix = suffix = version = s = ''

  %x{ #{cmd} }.lines do | p |
    puts ">> #{p}" if options[:verbose]
    m = pat.match( p )
    if m
      prefix  = m[:pfix] if prefix  != m[:pfix]
      version = m[:vers] if version != m[:vers]
      suffix  = m[:sfix] if suffix  != m[:sfix]
      key = "#{prefix}#{version}-#{MAGICSTR}#{suffix}"
      lkpackages[ key ] << m[:dash]
      ## puts "  '#{m[:dash]}'"
    end
  end
end

puts "lkpackages -- #{lkpackages}" if options[:debug] >= DBGLVL2

# Create a comparison range: options[:greaterthan]...options[:lessthan]
# substituting 0 and 10000 if either or both of these options are not specified:
hidash = options[:lessthan]    || 10000
lodash = options[:greaterthan] || 0
# This range comparison must *exclude* >both< of the end-points!
lodash += 1 if lodash > 0
dashrange = Range.new( lodash, hidash, true )  # exclusive: ...

lkpackages.each do | key, arry |
  arry.each do | vrs |
    lk2purge[ key ] << vrs if dashrange.include?( vrs.to_i )
  end
end

puts "lk2purge -- #{lk2purge}" if options[:debug] >= DBGLVL2

exit true
