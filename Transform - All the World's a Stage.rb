#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Transform - All the World's a Stage.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.1, 10/16/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# A demo, based on the following irb session, of how to transform a text
# "all in one go..."

# alikot$ irb
# >> s = "All the world's a stage, and all the men and women merely players."
# => "All the world's a stage,\n and all the men and women merely players."
#
# >> r = Hash.new                 # => {}
#
# >> r["stage"] = "string"        # => "string"
# >> r["players"] = "characters"  # => "characters"
#
# >> puts s.gsub(/stage|players/,r)
#All the world's a string,
# and all the men and women merely characters...
# >>

# Usage:  $ ruby "Transform - All the World's a Stage.rb"
# or to see intermediate objects' values:
#         $ ruby "Transform - All the World's a Stage.rb" true

sourcetext = <<EOT
All the world's a stage,
  And all the men and women merely players;
  They have their exits and their entrances,
  And one man in his time plays many parts,
  His acts being seven ages.
EOT

puts ''
puts sourcetext
puts '-'*72

# Specify each target/replacement word-pair exactly once (DRY);
# use these arrays of words to calculate both the replacement-
# correspondence hash and the search-regex itself:
targetwords = %w{ stage players exits entrances
                  man parts acts ages }
replwords   = %w{ string characters substitutions interpolations
                  character instances objects regular\ expressions }

# Replacement-correspondence word hash:
replhash = Hash.new
targetwords.each_with_index { | tw, i | replhash[tw] = replwords[i] }

# replhash = { targetwords[0] => replwords[0],
#              targetwords[1] => replwords[1],
#              targetwords[2] => replwords[2],
#              targetwords[3] => replwords[3],
#              targetwords[4] => replwords[4],
#              targetwords[5] => replwords[5],
#              targetwords[6] => replwords[6],
#              targetwords[7] => replwords[7]
#             }

# Regex is a chain of alternate-literals:
regextext = targetwords.join( '|' )

# Optional intermediate objects' values:
puts "\nreplhash = '#{replhash}'\nregextext = '#{regextext}'\n\n" if ARGV[0]

# Do all word-replacements all-in-one-go! --
transformed = sourcetext.gsub( /#{regextext}/, replhash )

puts transformed
puts ''

exit
