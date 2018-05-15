#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringModes.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 05/15/2018
#

class String

  # Convert a mode_human_readable(_VMS) string
  # back into an integer mode/permission value
  def to_mode( base = "" )
    # " O:rwx G:rwx W:rwx" => "rwxrwxrwx"
    # (also remove any directory, link, sticky-bit indicators)
    m = self.delete( "UGWO: dlst" )
    # "r--r-xrwx" => "100101111" (binary bit-string)
    m.tr!( "rwx", "1" )  # set bits
    m.tr!( "-", "0" )    # clear bits
    m = m.to_i(2)
    case base.to_sym
    when :oct, :octal
      return sprintf( "%2s%o", '%o', m )
    when :dec, :decimal
      return sprintf( "%d", m )
    when :hex, :hexadecimal
      return sprintf( "%2s%x", '%x', m )
    when :bin, :binary
      return sprintf( "%2s%b", '%b', m )
    else  # when base is "" (or misspelt...)
      return sprintf( "%o", m )      # "natural", unadorned octal
    end  # case base
  end  # to_mode

end  # class String
