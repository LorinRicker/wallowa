#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# GetPrompted.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.1, 05/09/2018
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# require and include done here as a courtesy, as nearly all uses
# of prompting can benefit from readline completions:
require_relative 'AppCmdCompletions'
include AppCmdCompletions

# GetPrompted returns a +response+ (string) from the user as prompted,
# or returns a +default+ response (string) if available and the user
# accepts that default by pressing the <Enter> key.
# Prompt-termination punctuation is a colon ":".
# returnexit set true lets caller receive and handle the exit itself.
def getprompted( prompt, default, returnexit = false )
  dstr ||= default
  pstr = prompt + ( dstr == "" ? ": " : " [#{dstr}]: " )
  response = readline( pstr, true ).strip
  if response.downcase == "exit" || response.downcase == "quit"
    # Always restore terminal echo:
    `stty echo`
    exit true  # this exit always provides cmd-line status:0
  end
  return ( response != "" ? response : dstr )
rescue StandardError
  return false if returnexit  # to let caller handle the exit on its own...
  # otherwise:
  # Always restore terminal echo:
  `stty echo`
  exit true  # this exit always provides cmd-line status:0
end #getprompted

def getprompted_noecho( prompt, default, returnexit = false )
  require_relative 'WhichOS'
  os  = WhichOS.identify_os
  case os
  when :linux
    echooff = "stty -echo"
    echoon  = "stty echo"
  when :vms
    echooff = "SET TERMINAL /NOECHO"
    echoon  = "SET TERMINAL /ECHO"
  end  # case os
  `#{echooff}`
  response = getprompted( prompt, default, returnexit )
  `#{echoon}`
  return response
end # getprompted_noecho
