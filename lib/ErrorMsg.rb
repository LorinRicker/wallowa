#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ErrorMsg.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 04/29/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Intelligently formatted error messages --

require_relative '../lib/TermChar'

module ErrorMsg

  SPC = ' '

  def self.putmsg( msgpreamble, msgtext, msgline2 = '' )
    msgtext  = SPC + msgtext  if msgtext[0] != SPC
    msgline2 = SPC + msgline2 if msgline2 != '' && msgline2[0] != SPC
    msg      =  msgpreamble + msgtext
    if msgpreamble.size + msgtext.size + msgline2.size < TermChar.terminal_width
      msg += msgline2
    else
      msg += "\n#{SPC*msgpreamble.size}" + msgline2
    end
    $stderr.puts msg
  end  # putmsg

end  # module ErrorMsg
