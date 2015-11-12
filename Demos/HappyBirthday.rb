#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# HappyBirthday.rb
#
# Copyright © 2014-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 12/15/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

def happybirthday( who )
  4.times { |i| puts "Happy Birthday #{ i == 2 ? "dear #{who}!" : "to you." }" }
end  # happybirthday

ARGV[0] ||= 'Doggie'
happybirthday ARGV[0]
