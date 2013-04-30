#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Prompted.rb
#
# Copyright © 2011-12 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.9, 07/15/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'readline'        # See "Pickaxe v1.9", p. 788
include Readline          #
require 'abbrev'          #                   , p. 720
require 'pp'

COMMANDS = %w{ exit quit }
  ABBREV = COMMANDS.abbrev
Readline.completion_proc = proc do |string|
  ABBREV[string]
end  # proc

# if askprompted( "Continue", "N" ) then...
# if askprompted( "Continue" ) then ...
def askprompted( pstr, dstr = "Y" )
  # expects a Yes or No response,
  # returns true for any response beginning with "Y" or "y",
  # returns false for everything else...
  # but does test & respond to exit/quit/Ctrl-D/Ctrl-Z...
  default ||= dstr
  prompt = pstr + ( default == "" ? " (y/n)? " : " (y/n) [#{default}]? " )
  answer = readline( prompt, true ).strip.downcase
  exit true if answer == "exit" || answer == "quit"
  answer = default.downcase if answer == ""
  return ( answer[0] == "y" ? true : false )
rescue StandardError
  exit true  # this exit always provides cmd-line status:0
end # askprompted

def getprompted( pstr, dstr )
  # "remembers" the last value entered by user
  # and offers it as the current default...
  default ||= dstr
  prompt = pstr + ( default == "" ? ": " : " [#{default}]: " )
  response = readline( prompt, true ).strip
  exit true if response.downcase == "exit" || response.downcase == "quit"
  return ( response != "" ? response : default )
rescue StandardError
  exit true  # this exit always provides cmd-line status:0
end # getprompted

def promptcycle( pstr, dstr, pat, options )
  goodval = nil
  while ! goodval
    val = getprompted( pstr, dstr )
    within  = ""
    goodval = val.match( pat )
    #~ puts "goodval: '#{goodval ? "true" : "nil" }'"
    if goodval
      #~ response = val.???conversion???
      if options[:validrange]
        within  = " within " + options[:validrange].to_s
        goodval = options[:validrange].cover?( response )
      end  # if options[:validrange]
    end  # if goodval
    puts "\n#{options[:reprompt]}#{within}\n" if ! goodval
  end  # while !goodval
  return [ goodval, goodval ? val : nil ]
end  # promptcycle

# Parameter options (hash) has the following (optional) keys:
#   :reprompt (string)   -- A re-prompt displayed if user enters
#                           an incorrect (bad) value for the type
#                           of data requested
#   :validrange (range)  -- A range (min..max) which covers the
#                           valid values for the user to enter
def ultraprompted( pstr, dstr = "Y", options = {} )
  default ||= dstr
  resptype  = dstr.class.to_s
  phrase    = resptype.article( true )
  # Default reprompt string, caller should provide a better/specific one:
  options[:reprompt] ||= "Bad value, please re-enter #{phrase}"
  case resptype
  when "String"
    response = getprompted( pstr, dstr )
  when "Integer", "Fixnum"
    pat = /^\w*\d+\w*$/
    goodval, val = promptcycle( pstr, dstr, pat, options )
    response = goodval ? val.to_i : nil
  when "Float"
    pat = /^\w*\d+\.?\d*\w*$/
    goodval, val = promptcycle( pstr, dstr, pat, options )
    response = goodval ? val.to_f : nil
  else
    response = nil
    puts "Unknown type #{resptype}"
  end  # case dclass
  return response
#~ rescue StandardError
  #~ exit true  # this exit always provides cmd-line status:0
end  # ultraprompted
