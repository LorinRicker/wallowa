#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# appconfig.rb
#
# Copyright © 2012-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 02/01/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'yaml'
#~ require 'pp'

# -----

class AppConfig

  # Verify the existence of an app-specific directory for a configuration
  # file in ~/home, create it if it's missing.
  def self.check_yaml_dir( confdir, perms = 0700 )
    Dir.mkdir( confdir, perms ) if ! Dir.exists?( confdir )
  end  # check_yaml_dir

  # Save or (re)load an app-specific configuration file (YAML).
  def self.configuration_yaml( cfile, config, force_save = false )
    check_yaml_dir( File.dirname(cfile) )
    if ! force_save && File.exists?( cfile )
      return YAML.load_file( cfile )
    else
      File.open( cfile, 'w' ) { |f| YAML::dump( config, f ) }
      $stderr.puts "%YAML-i-init, config-file #{cfile} initialized"
      return {}
    end  # if File.exists? cfile
  end  # configuration_yaml

end  # class AppConfig
