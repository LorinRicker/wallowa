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

module ErrorMsg

  COMMA = ','
  SPC   = ' '

  # Intelligently formatted error messages -- for example:
  #
  # %PROGNAME-i-abbr, message text
  #
  # or:
  #
  # %PROGNAME-i-abbr, main message text
  #                   extra line of message #1
  #                   [ extra line of message #2
  #                     extra line of message #3 ]...
  #
  def self.putmsg( msgpreamble, msgtext, *extralines )
    msgpreamble.strip!
    msgpreamble += COMMA if msgpreamble[-1] != COMMA
    msgpreamble += SPC
    msgtext.strip!

    msg = msgpreamble + msgtext

    if extralines  # is not nil
      # mlines = extralines.respond_to?( :each ) ? extralines : [ extralines ]
      mlines.each do | ml |
        ml.strip if ml != ''
        msg += "\n#{SPC*(msgpreamble.size+1)}" + ml
      end
    end

    $stderr.puts msg

  end  # putmsg

end  # module ErrorMsg

# === Main/test/demo ===
if $0 == __FILE__
  ErrorMsg.putmsg( "%ERRORMSGTEST-i-test", "this is a test" )
end
