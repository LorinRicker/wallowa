#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# ANSIseq.rb
#
# Copyright © 2011-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.2, 12/06/2016
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# With full props and acknowledgment to Avdi Grimm and Ruby Tapas Episode 490,
# Crash Logger (https://www.rubytapas.com/2017/07/31/episode-490-crash-logger/)

# Use -- In a Ruby script:
#  require_relative 'lib/CrashLogger'

require "yaml"

module CrashLogger
  def self.log_crash_info(error=$!)
    program_name = $0
    process_id   = $$
    timestamp    = Time.now.utc.strftime("%Y%m%d-%H%M%S")

    filename = "crash-#{program_name}-#{process_id}-UTC#{timestamp}.yml"

    error_info = {}
    error_info["error"]       = error
    error_info["stacktrace"]  = error.backtrace
    error_info["environment"] = ENV.to_h

    File.write(filename, error_info.to_yaml)
    filename
  end
end

at_exit do
  unless $!.nil? || $!.is_a(SystemExit)
    fname = CrashLogger.log_crash_info
    $stderr.puts "%%% Crash log has been saved to: #{fname}"
  end
end
