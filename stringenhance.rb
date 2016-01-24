#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# stringenhance.rb
#
# Copyright © 2011-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.7, 10/15/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative 'lib/StringEnhancements'
require 'pp'

# Main -- test drivers:
def mdriver( m )
  puts "'#{m}' => #{sprintf( "%#4o", m.to_mode )} oct or #{m.to_mode} dec"
end  #

def ucdriver( cm, s )
  pp s
  puts "  => '#{s.uncomment(cm).compress}'"
end  #

if $0 == __FILE__ then
  # VMS ER$Compress:
  t = "  This    is\ta\t      spacey     test.    "
  puts "Compressing '#{t}' => '#{t.compress}'"

  # VMS ER$Collapse:
  t = "    Collapse\tAll\tThis        Whitespace!   "
  puts " Collapsing '#{t}' => '#{t.collapse}'"
  puts "    Editing '#{t}' => '#{t.edit("collapse,capcase")}'"
  puts "    Editing '#{t}' => '#{t.edit("collapse,upcase")}'"

  # VMS F$Element lexical:
  s = "abc,def,ghi,jkl,mno"
  puts "\nstring s: '#{s}'"
  puts "1st element of s is '#{s.element(0)}'"
  puts "2nd element of s is '#{s.element(1)}'"
  puts "5th element of s is '#{s.element(4)}'"
  s = "XYZ;ABC;PQR"
  puts "string s: '#{s}'"
  puts "3rd element of s is '#{s.element(2,";")}'"
  puts "4th element of s is '#{s.element(3,";")}'"

  # Separators by thousands:
  puts "\n     123456789 => '#{"123456789".thousands}'"
  puts "      12345678 => '#{"12345678".thousands(".")}'"
  puts "         12345 => '#{"12345".thousands}'"
  puts "         12345 => '#{"12345".edit("thousands", ".")}' (with edit(\"thousands\", \".\"))"
  puts "         12345 => '#{"12345".edit("groupsep", 4, ".")}' (with edit(\"groupsep\", 4, \".\"))"
  puts "           345 => '#{"345".thousands}'"
  puts "10000000000000 => '#{"10000000000000".thousands}' (10-trillion)"

  # Group-by 4's (or larger):
  puts "\n1222333444555666777888999 => '#{"1222333444555666777888999".groupsep(4,";")}'"

  # but what else can groupsep be used for?
  # How about IP addresses and MAC addresses...
  puts "\n        localhost => '#{"127000000001".groupsep(3,".")}'"
  puts "static private IP => '#{"010000001021".groupsep(3,".")}'"
  puts "     network mask => '#{"255255255000".groupsep(3,".")}'"
  puts "      MAC address => '#{"C43DC74784C7".groupsep(2,":")}'"

  # Convert human-readable permission/mode strings to integer modes:
  puts "\n"
  mdriver( "rwxrwxrwx" )
  mdriver( "drwxrwxrwx" )
  mdriver( "rwxrw-r--" )
  mdriver( " O:rwx G:rw- W:r--" )
  mdriver( " O:rwx G:--- W:---" )
  mdriver( " O:--- G:rwx W:---" )
  mdriver( " O:--- G:--- W:rwx" )

  # uncomment:
  puts "\n"
  ucdriver( "#", "   # Ruby-Perl-Python-bash style comment" )
  ucdriver( "#", "  str.sort.reverse    # Ruby-style comment" )
  ucdriver( "!", "$ ! A full-line DCL-style comment" )
  ucdriver( "!", "$ sym == \"Value is ''val'\"  ! DCL-style comment" )
  ucdriver( ";", "  ;; Lisp-style document-header comment" )
  ucdriver( ";", "  (q foo bar)  ; Lisp-style comment" )
  ucdriver( "{", "  ctr := ctr + 1  { Pascal-style comment }" )
  ucdriver( "{", "  if cond { internal Pascal-style comment } then")
  ucdriver( "/*", "  ctr = ++ctr    /* C-style comment */" )
  ucdriver( "/*", "  while cond   /* internal C-style comment */ { stmt }" )
end
