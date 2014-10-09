#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# AppCmdCompletions.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 10/08/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Define the readline command-completion vocabulary for this application.
module AppCmdCompletions

require 'abbrev'          # See "Pickaxe v1.9 & 2.0", p. 731
require 'readline'        # See "Pickaxe v1.9 & 2.0", p. 795
include Readline          #

  # Command vocabulary always includes "exit" and "quit".
  def app_cmd_completions( commands  )
    # Establish the full set of command abbreviations:
    vocab = commands + %w{ exit quit }
    cmd   = vocab.abbrev
    # Load these into Readline; now any invocation of the +readline+ method
    # will have these abbreviations available: ex<Tab> => exit (etc.)
    Readline.completion_proc = -> str { cmd[str] }
    return cmd
  end  # app_cmd_completions

end  # module
