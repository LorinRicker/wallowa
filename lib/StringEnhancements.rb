#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringEnhancements.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 05/15/2018
#
# Refactored into:
#   StringCases, StringGroupings, StringIsIn,
#   StringLexicals, StringModes, and StringSpellings
#
# This file now is merely a single-point "require_relative" for
# each/all of the above, each of which can be used separately
# and selectively, of course.
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative "StringCases"
require_relative "StringGroupings"
require_relative "StringIsIn"
require_relative "StringLexicals"
require_relative "StringModes"
require_relative "StringSpellings"
