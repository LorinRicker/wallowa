#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# GetPrompted.rb
#
# Copyright © 2011 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.4, 04/14/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'readline'        # See "Pickaxe v1.9", p. 788
include Readline          #
require 'abbrev'          #                   , p. 720

COMMANDS = %w{ exit quit }
  ABBREV = COMMANDS.abbrev
Readline.completion_proc = proc do |string|
  ABBREV[string]
  end  # proc

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
end #getprompted
