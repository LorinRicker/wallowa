#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# mdrender.rb
#
# Copyright © 2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Inspired by:
# http://stackoverflow.com/questions/7694887/is-there-a-command-line-utility
#                                    -for-rendering-github-flavored-markdown

# -----

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.1 (01/05/2016)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

# -----

require 'github/markdown'

puts GitHub::Markdown.render_gfm File.read(ARGV[0])
