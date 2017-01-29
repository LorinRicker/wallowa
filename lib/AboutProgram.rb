#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# AboutProgram.rb
#
# Copyright © 2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 01/29/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

class Object

def about_program( programid, rubycoder, exitif )
  $stdout.puts "#{programid} ...on Ruby v#{RUBY_VERSION}"
  $stdout.puts "#{rubycoder}"
  if exitif
    exit( true )  # just terminate program
  else
    return( true )  # return true for options[:about]
  end
end  # about_program

end  # class
