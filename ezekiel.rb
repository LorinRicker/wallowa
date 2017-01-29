#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ezekiel.rb
#
# Copyright © 2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# This program is a >toy< which plays with the (bogus) numerology/gematria
# espoused by the 2007 novel "The Ezekiel Code" by Gary Val Tenuta (Outskirts
# Press).  Tenuta's numerology (algorithm, referred to as "cross-adding") is
# spelled out in Chapter ~2~ of the novel.  The plot of this story hinges upon
# the "great significances" of various phrases and words as cross-added by this
# numerology --
# See the companion text file "Ezekiel Numerology Test Phrases.cross_sums" for
# a (nearly) complete list of cross-added phrases/words (and noting a few errors
# in the novel-author's own sums).
#
# The author of this >program< in no way endorses, or even believes in, the
# numerological and/or religious notions and ideas put forth ion that novel;
# however, it is amusing to play with (and cross-check) the various sums and
# cross-sums from that work of fiction -- if only to demonstrate that one can
# "make great significance" out of damn near any/every cross-sum you can compute!
#

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.1 (01/29/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

ASCII_A = 65  # ASCII code character value for letter 'A'

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require 'pp'
require_relative 'lib/SumOfDigits'
require_relative 'lib/GetPrompted'
require_relative 'lib/ANSIseq'
require_relative 'lib/AboutProgram'

# ==========
def ezekiel( wordphrase, alphahash )
  phrase = wordphrase.upcase
  sum = 0
  phrase.chars.each { |letter| sum += alphahash[letter] }
  result = sum.sumof( 1 )
  result["phrase"] = phrase
  result["Ezekiel\#"] = sum
  return result
end

# === Main ===
options = { :prompt   => false,
            :offset   => 0,
            :noop     => false,
            :verbose  => false,
            :debug    => DBGLVL0,
            :about    => false
          }

optparse = OptionParser.new { |opts|
  opts.on( "-p", "--prompt", "Prompt mode: prompt for more than one word-phrase" ) do |val|
    options[:prompt] = true
  end  # -p --prompt
  opts.on( "-o", "--offset", "=OFFSET", Integer,
           "Value offset for letter \"A\" (default: ASCII_A or 65)" ) do |val|
    options[:offset] = val.to_i
  end  # -o --offset
  opts.separator ""
  # -n --dryrun not implemented, not needed for this program:
  # opts.on( "-n", "--noop", "--dryrun", "--test",
  #          "Dry-run (test & display, no-op) mode" ) do |val|
  #   options[:noop]  = true
  #   options[:verbose] = true  # Dry-run implies verbose...
  # end  # -n --noop
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
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "  Computes the gematria (cross-sum) of a word-phrase ala 'The Ezekiel Code'." +
                "\n\n  Usage: #{PROGNAME} [options] \"phrase to compute\"" +
                "\n\n"
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

# Initializations --
pstr = 'phrase'

# Create a hash of { "A" => 1, "B" => 2, ... }
alphahash = Hash.new( 0 )  # return 0 (zero) for any undefined hash element
(1..26).each { |v| alphahash[(v-1+ASCII_A).chr] = v +options[:offset]}
pp alphahash if options[:debug] > 1

if ARGV[0]
  # Process all phrases (args) on command-line, even if prompt-mode is requested...
  ARGV.each do | arg |
    cross_sum = ezekiel( arg, alphahash )
    puts "\nEzekiel(\"#{arg.upcase}\") --> #{cross_sum["Ezekiel\#"]}\n"
    pp cross_sum
  end
end
if options[:prompt]
  # ...Prompt user for phrases/words, calculate Ezekiel-# for each...
  # "empty" response ([Enter]) and Ctrl/D to end/terminate...
  while wordphrase = getprompted( "\n#{pstr}", "", true )
    break if wordphrase == ""
    cross_sum = ezekiel( wordphrase, alphahash )
    puts "\nEzekiel(\"#{wordphrase.upcase}\") --> #{cross_sum["Ezekiel\#"]}\n"
    pp cross_sum
  end  # while
end

exit true
