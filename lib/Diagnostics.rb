#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Diagnostics.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 08/08/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'

module Diagnostics

  def Diagnostics.diagnose( obj, label = nil, lineno = nil )
    here = label ? " #{label}" : ''
    here = "#{here} at line:#{lineno}" if lineno
    selfname = "#{'='*8} #{self.name}#{here} #{'='*8}"
    puts selfname
    printf( "\n<%s, len:%d - %x>\n", obj.class, obj.size, obj.object_id )
    puts "\nobject is a member of the #{obj.class} class"
    pp obj
    puts
    #obj.each { |e| pp e }
    puts '='*selfname.length
  end  # diagnose


end  # module Diagnostics
