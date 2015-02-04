#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# AskPrompted.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 02/03/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# require and include done here as a courtesy, as nearly all uses
# of prompting can benefit from readline completions:
require_relative 'AppCmdCompletions'
include AppCmdCompletions

# AskPrompted returns a +true+ (boolean) if the user enters an affirmative
# '[Yy]...' response to the prompt, or returns a +false+ response (boolean)
# if the user enters a negative '[Nn]...' response (or any non-affirmative
# response); the +default+ response can be set to either "Y" or "N" ("Y" is
# the default +default+).
# Prompt-termination punctuation is a question mark "?".
# For example:
#   if askprompted( "Continue" ) then ...
#   if askprompted( "Continue", "N" ) then...
def askprompted( prompt, default = "Y" )
  # expects a Yes or No response,
  # returns true for any response beginning with "Y" or "y",
  # returns false for everything else...
  # but does test & respond to exit/quit/Ctrl-D/Ctrl-Z...
  dstr ||= default
  pstr = prompt + ( dstr == "" ? " (y/n)? " : " (y/n) [#{dstr}]? " )
  answer = readline( pstr, true ).strip
  exit true if answer.downcase == "exit" || answer.downcase == "quit"
  answer = dstr if answer == ""
  return ( answer[0].downcase == "y" ? true : false )
rescue StandardError
  exit true  # this exit always provides cmd-line status:0
end #askprompted
