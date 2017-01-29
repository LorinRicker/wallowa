#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# AppCmdCompletions.rb
#
# Copyright © 2014-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.2, 02/13/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Ruby Version Dependency: uses Ruby v2.x keyword arguments syntax

# Define the readline command-completion vocabulary for this application.
module AppCmdCompletions

  class EmptyVocabulary < Exception; end

  require 'abbrev'          # See "Pickaxe v1.9 & 2.0", p. 731
  require 'readline'        # See "Pickaxe v1.9 & 2.0", p. 795
  include Readline          #

  # Parameter command can be a string of words, or an array of words:
  #   "ant bear cat dog" or %w{ ant bear cat dog }
  # Command vocabulary may conditionally include "exit" & "quit", "yes" & "no".
  def app_cmd_completions( commands, exitquit: false, yesno: false  )
    # Establish the full set of command abbreviations:
    vocab  = commands.kind_of?( String) ? commands.split : commands
    vocab += %w{ exit quit } if exitquit
    vocab += %w{ yes no }    if yesno
    raise EmptyVocabulary, "Command vocabulary for readline completion is empty" if vocab == []
    cmd    = vocab.abbrev
    # Load these into Readline; now any invocation of the +readline+ method
    # will have these abbreviations available: ex<Tab> => exit (etc.)
    Readline.completion_proc = -> str { cmd[str] }
    return cmd
  end  # app_cmd_completions

end  # module
