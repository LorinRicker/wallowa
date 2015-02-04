#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Prompted.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 02/03/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'pp'
require_relative 'AskPrompted'
require_relative 'GetPrompted'

# require and include done in [Ask|Get]Prompted as a courtesy, as nearly
# all uses of prompting can benefit from readline completions --
## require_relative 'AppCmdCompletions' (...done in [Ask|Get]Prompted)
## include AppCmdCompletions

def promptcycle( prompt, default, pat, promptions )
  goodval = nil
  while ! goodval
    val = getprompted( prompt, default )
    within  = ""
    goodval = val.match( pat )
    #~ puts "goodval: '#{goodval ? "true" : "nil" }'"
    if goodval
      #~ response = val.???conversion???
      if promptions[:validrange]
        within  = " within " + promptions[:validrange].to_s
        goodval = promptions[:validrange].cover?( response )
      end
    end
    $stdout.puts "\n#{promptions[:reprompt]}#{within}\n" if ! goodval
  end  # while !goodval
  return [ goodval, goodval ? val : nil ]
end  # promptcycle

# Parameter options +promptions+ (hash) has the following (optional) keys:
#   :reprompt (string)   -- A re-prompt displayed if user enters
#                           an incorrect (bad) value for the type
#                           of data requested
#   :validrange (range)  -- A range (min..max) which covers the
#                           valid values for the user to enter
def ultraprompted( prompt, default = "Y", promptions = {} )
  default ||= default
  resptype  = default.class.to_s
  phrase    = resptype.article( true )
  # Default reprompt string, caller should provide a better/specific one:
  promptions[:reprompt] ||= "Bad value, please re-enter #{phrase}"
  case resptype
  when "String"
    response = getprompted( prompt, default )
  when "Integer", "Fixnum", "Bignum"
    pat = /^\w*\d+\w*$/
    goodval, val = promptcycle( prompt, default, pat, promptions )
    response = goodval ? val.to_i : nil
  when "Float"
    pat = /^\w*\d+\.?\d*\w*$/
    goodval, val = promptcycle( prompt, default, pat, promptions )
    response = goodval ? val.to_f : nil
  else
    response = nil
    $stderr.puts "%ultraprompted-e-unktyp, unknown type #{resptype}"
  end  # case dclass
  return response
#~ rescue StandardError
  #~ exit true  # this exit always provides cmd-line status:0
end  # ultraprompted
