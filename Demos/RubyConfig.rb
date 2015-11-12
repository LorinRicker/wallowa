#!/usr/bin/ruby1.9.1
# -*- encoding: utf-8 -*-

# RubyConfig.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 07/27/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'rbconfig'
#~ require 'pp'

#~ RubyConfig.rb:xx: Use RbConfig instead of obsolete and deprecated Config
# Main -- test drivers:
if $0 == __FILE__ then
  # Extract the Config::CONFIG hash's keys,
  # sort them case-insensitive,
  # then use each sorted key to extract and
  # print the corresponding Config::CONFIG value...
  keys = []
  RbConfig::CONFIG.each_key { | k | keys << k }
  keys.sort! { |a,b| a.downcase <=> b.downcase }
  keys.each { | k | printf "\"%s\" => \"%s\"\n", k, RbConfig::CONFIG[ k ] }
end
