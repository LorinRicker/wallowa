#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# EnvironmentVariables.rb
#
# Copyright © 2011-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.4, 04/20/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require '~/projects/ruby/lib/pquts'

# Main -- test drivers:
if $0 == __FILE__ then
  ENV.each_key.sort.each { |k| puts "#{k} => #{ENV[k]}" }
  puts ""
  pquts ENV["SHELL"], 'ENV["SHELL"]'
  pquts ENV["LOGNAME"], 'ENV["LOGNAME"]'
  pquts ENV["USER"], 'ENV["USER"]'
  pquts ENV["HOME"], 'ENV["HOME"]'
  pquts ENV["TERM"], 'ENV["TERM"]'
  pquts ENV["PATH"], 'ENV["PATH"]'
  puts ""
  pquts ENV["GLOBIGNORE"], 'ENV["GLOBIGNORE"]'
  pquts ENV["GLOBOPTS"], 'ENV["GLOBOPTS"]'
#  pquts ENV["OSTYPE"], 'ENV["OSTYPE"]'
end
