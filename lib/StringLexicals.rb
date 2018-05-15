#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringLexicals.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 05/15/2018
#

require_relative "StringCases"
require_relative "StringGroupings"

class String

  alias uppercase     upcase
  alias locase        downcase
  alias lowercase     downcase
  alias capcase       capitalize
  alias trim          strip
  alias trim_leading  lstrip
  alias trim_trailing rstrip

  # Squeeze runs of whitespace down to single-blanks;
  #   a run of pure whitespace "    " returns ""
  def compress( whitespace = " \t" )
    self.tr( whitespace, " " ).squeeze( " " ).strip
  end  # compress

  # Collapse runs of whitespace down to ""
  def collapse( whitespace = " \t" )
    pat = Regexp.new( "[#{whitespace}]" )
    self.gsub( pat, "" )
  end  #collapse

  # Return the Nth (starting with 0) element from a delimited string
  def element( elno = 0, delimiter = "," )
    # returns "" (empty string) for non-existent elements
    element = self.split(delimiter)[elno]
    return !element.nil? ? element : ""
  end  # element

  # Strip comments from interior or end of string/line --
  # Comment forms handled:
  #   "#"          -- Ruby, Perl, Python, bash, etc. (to EOL)
  #   "!"          -- VMS/DCL (to EOL)
  #   ";"          -- Lisp, various macro-assembly languages (to EOL)
  #   "//"         -- Sublime Text, JSON, etc. (to end-of-line)
  #   "{ ... }"    -- Pascal
  #   "/* ... */"  -- C-style
  def uncomment( scommark = '#' )
    str = self.to_s
    ecommark = ''
    ecommark = '}'  if scommark == '{'
    ecommark = '*/' if scommark == '/*'
    scommark = Regexp.escape( scommark )
    # Match either to end-of-line or to closing-comment-mark:
    ecommark = ecommark.empty? ? '$' : Regexp.escape( ecommark )
    if m = str.match( "#{scommark}.*?#{ecommark}" )
      str[m.begin(0)..m.end(0)] = ""
    end  # ...str.match
    str
  end  # uncomment

  # Group-edit a string, applying compress, collapse, trim,
  # cap/up/lo-case, grouping &/or uncommenting as requested
  def edit( editlist, *param )
    i = 0
    s = self.to_s
    e = "x"
    while e != ""
      e = editlist.downcase.element(i)
      s = case e.to_sym
          when :collapse
            s.collapse
          when :compress
            s.compress
          when :lowercase, :locase, :downcase
            s.downcase
          when :uppercase, :upcase
            s.upcase
          when :capcase, :capitalize
            s.capitalize
          when :titlecase
            s.titlecase
          when :trim, :strip
            s.strip
          when :trim_leading, :lstrip
            s.lstrip
          when :trim_trailing, :rstrip
            s.rstrip
          when :element
            elem = param[0] || 0
            sep  = param[1] || ","
            s.element( elem, sep )
          when :groupsep
            grp = param[0] || 3
            sep = param[1] || ","
            s.groupsep( grp, sep )
          when :thousands
            sep = param[0] || ","
            s.thousands( sep )
          when :uncomment
            s.uncomment( param[0] )
          else
            break
          end  # case
      i += 1
    end  # while
    return s
  end  # edit

end  # class String
