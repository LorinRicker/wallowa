#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# regex.rb
# (renamed from 'RegexRevealed.rb' to conform to rel2bin.rb conventions)
#
# Copyright © 2011-2014 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'optparse'  # See "Pickaxe v1.9", p. 776
require 'readline'  #                   , p. 788
include Readline    #
require 'abbrev'    #                   , p. 720
require_relative 'GetPrompted'
require_relative 'ANSIseq'

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.6 (08/28/2014)"
  AUTHOR = "Lorin Ricker, Franktown, Colorado, USA"

  LA = '>'.color(:red)
  RA = '<'.color(:red)
  SL = '/'.color(:green)
  SQ = "'".color(:green)
  CI = 'i'.color(:green)

  IND1 = " " * 4
  IND2 = " " * 14
  IND3 = IND1 + IND2
   SEP = "-" * 16

def showregex( sstr, rstr, options )
  reopt = ( options[:caseinsensitive] ? Regexp::IGNORECASE : nil )
  shopt = ( options[:caseinsensitive] ? CI : "" )
  printf( "string: " + "#{SQ}%s#{SQ}\n", sstr.bold ) if options[:verbose]
  printf( " regex: " + "#{SL}%s#{SL}%s\n", rstr.bold, shopt.bold ) if options[:verbose]

  pat = Regexp.new( rstr, reopt )
  m = pat.match( sstr )
  if m
    puts SEP   # display the exemplars:
    printf( "#{IND1}" + "#{SL}%s#{SL} %s #{SQ}%s#{SQ}\n",
                        rstr.bold, "=~".bold.color(:red), sstr.bold )
    printf( "#{IND1}" + "#{SL}%s#{SL}.%s(#{SQ}%s#{SQ})\n\n",
                        rstr.bold, "match".bold.color(:red), sstr.bold )
    # display the match results:
    printf( "#{IND1}" + "Result".underline + ": %s\n\n",     \
            "#{m.pre_match}".bold.color(:blue)               \
            + "#{LA}" + "#{m[0]}".bold.color(:red) + "#{RA}" \
            + "#{m.post_match}".bold.color(:blue) )
    # display the match metadata:
    printf( "#{IND1}m[0], $&, m.to_a => %s\n", m.to_a.to_s.bold.color(:red) )
    printf( "#{IND1}     # of groups => %s\n", m.captures.length.to_s.bold.color(:red) )
    printf( "#{IND1}      m.captures => %s\n", m.captures.to_s.bold.color(:red) )
    printf( "#{IND1}         m.names => %s\n", m.names.to_s.bold.color(:red) )
    m.to_a.each_index do |i|
      printf( "#{IND3}$#{i} => %s%s%s\n", \
              "\"#{m[i]}\"".bold.color(:red), \
              ( i==0 ? "  # same as m[0] and $&" : "  # same as m[#{i}]" ), \
              ( (i >= 1) && (m.names.length > 0) ? " and m[:#{m.names[i-1]}]" : "" ) )
      printf( "#{IND3}offset: %s, length: %d\n", \
              m.offset(i).to_s, ( m.end(i) - m.begin(i) ) )
    end  # m.to_a.each_index
    puts SEP
  else
    puts "#{SEP}\n#{IND1}" + "No match".underline + "\n#{SEP}"
  end
  return m
end  #showregex

# === Main ===
options = {}  # hash for all com-line options;
              # see http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
              # and http://ruby.about.com/od/advancedruby/a/optionparser.htm ;
              # also see "Pickaxe v1.9", p. 776

optparse = OptionParser.new do |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options]       # Ctrl/D or 'exit' to exit"
  opts.on( "-h", "-?", "--help", "Display this help text" ) do |val|
    puts opts
    exit
  end
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
  end
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end
  opts.on( "-i", "--caseinsensitive", "Pattern-matching is case-insensitive" ) do |val|
    options[:caseinsensitive] = true
  end
# Actually, these regexp options are impractical for this exerciser:
#  opts.on( "-e", "--extended", "Ignore spaces and newlines in regexp" ) do |val|
#    options[:extended] = true
#    end
#  opts.on( "-m", "--multiline", "Newlines treated as ordinary character" ) do |val|
#    options[:multiline] = true
#    end
end  #OptionParser.new
optparse.parse!  # leave residue-args in ARGV

printf( "Case %ssensitive pattern matching...\n\n", \
        ( options[:caseinsensitive] ? "in".underline : "" ) )

while ( sstr = getprompted( "Search string", sstr ) ) &&
      ( rstr = getprompted( " Regular expr", rstr ) )
  showregex( sstr, rstr, options )
end # while

# exit
