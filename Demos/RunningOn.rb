#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# RunningOn.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 09/02/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Main -- test drivers:
if $0 == __FILE__ then
  puts ""
  puts 'This Ruby is...'
  case RUBY_ENGINE.to_sym
  when :ruby     then puts "  Ruby - Matz's Ruby Interpreter (MRI)"
  when :macruby  then puts "  MacRuby - Ruby for Mac"
  when :jruby    then puts "  jRuby - Ruby on Java"
  when :rubinius then puts "  Rubinius - Ruby in Ruby"
  else puts "  #{RUBY_ENGINE} -- (other)"
  end
  puts "  #{RUBY_COPYRIGHT}"
  puts "  #{RUBY_DESCRIPTION}"
  puts "  ...on #{RUBY_PLATFORM}"
  puts ""
end
