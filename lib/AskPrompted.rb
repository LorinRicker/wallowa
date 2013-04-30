#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# AskPrompted.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.3, 04/14/2012
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

# if askprompted( "Continue", "N" ) then...
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
end #askprompted
