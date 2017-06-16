#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# SimplePrompted.rb
#
# Copyright © 2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 06/16/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# SimplePrompted returns a +true+ (boolean) if the user enters an affirmative
# '[Yy]...' response to the prompt, or returns a +false+ response (boolean)
# if the user enters a negative '[Nn]...' response (or any non-affirmative
# response); the +default+ response can be set to either "Y" or "N" ("Y" is
# the default +default+).
# Prompt-termination punctuation is a question mark "?".
# This variant does not use Standard Library Readline/readline.
# For example:
#   if simpleprompted( "Continue" ) then ...
#   if simpleprompted( "Continue", "N" ) then...
def simpleprompted( prompt, default = "Y" )
  # expects a Yes or No response,
  # returns true for any response beginning with "Y" or "y",
  # returns false for everything else...
  # but does test & respond to exit/quit/Ctrl-D/Ctrl-Z...
  dstr ||= default
  pstr = prompt + ( dstr == "" ? " (y/n)? " : " (y/n) [#{dstr}]? " )
  STDOUT.print( pstr )
  answer = STDIN.readline.strip
  exit true if answer.downcase == "exit" || answer.downcase == "quit"
  answer = dstr if answer == ""
  return ( answer[0].downcase == "y" ? true : false )
rescue StandardError
  exit true  # this exit always provides cmd-line status:0
end #simpleprompted
