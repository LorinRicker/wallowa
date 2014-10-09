#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# GetPrompted.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 10/08/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative 'AppCmdCompletions'
include AppCmdCompletions

# GetPrompted returns a +response+ (string) from the user as prompted,
# or returns a +default+ response (string) if available and the user
# accepts that default by pressing the <Enter> key.
# Prompt-termination punctuation is a colon ":".
def getprompted( prompt, default )
  dstr ||= default
  pstr = prompt + ( dstr == "" ? ": " : " [#{dstr}]: " )
  response = readline( pstr, true ).strip.downcase
  exit true if response == "exit" || response == "quit"
  return ( response != "" ? response : dstr )
rescue StandardError
  exit true  # this exit always provides cmd-line status:0
end #getprompted
