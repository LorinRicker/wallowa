#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# WhichOS.rb
#
# Copyright © 2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 09/12/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Which Operating System are we running on? --

module WhichOS

  def self.identify_os
    begin
      whichos = RUBY_PLATFORM  # s'posed to exist, but might not for some Rubies
    rescue NameError => e
      require 'rbconfig'
      whichos = RbConfig::CONFIG['host_os']
    ensure
      case whichos.downcase
      when /linux/
        return :linux
      when /openvms/
        return :vms     # don't match just "VMS", might get "Virtual MachineS"
      when /unix/
        return :unix
      when /windows/
        return :windows
      else
        abort( whichos )
      end
    end
  end  # identify_os

end  # module WhichOS
