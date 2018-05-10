#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringEnhancements.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.5, 05/10/2018
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative "StringIsIn"

class String

  alias uppercase     upcase
  alias locase        downcase
  alias lowercase     downcase
  alias capcase       capitalize
  alias trim          strip
  alias trim_leading  lstrip
  alias trim_trailing rstrip

# -----

  # Return boolean indicating if *all* alpha-characters in word
  # (or filename) are of the specified regex-case:
  def isallXcase?( rex )
    s = self.gsub( /[\W\d.,;:!?-]/, "" )
    s.split( "" ).all? { |c| c =~ rex }
  end  # isallXcase?

  # Return boolean indicating if *all* alpha-characters in word
  # (or filename) are lower-case:
 def isalldowncase?
    isallXcase?( /[a-z]/ )
  end  # isalldowncase?

  # Return boolean indicating if *all* alpha-characters in word
  # (or filename) are UPPER-CASE:
  def isallUPCASE?
    isallXcase?( /[A-Z]/ )
  end  # isallUPCASE?

  # Return boolean indicating if the alpha-characters in word
  # (or filename) are Mixed-Case (that is, not all lower-case
  # and not all UPPER-CASE):
  def isMixedCase?
    ! isallXcase?( /[a-z]/ ) and ! isallXcase?( /[A-Z]/ )
  end  # isMixedCase?

# -----

  # Title case means to capitalize each word in string,
  # incidentally doing a string compress at the same time
  def titlecase
    capwords = []
    words = self.split
    words.each { |w| capwords << w.capitalize }
    return capwords.join( " " )
  end  # titlecase

  # Return either "an" if word begins with a vowel, return "a" otherwise
  def article( fullphrase = false )
    article = self[0] =~ /[aeiou]/i ? "an" : "a"
    article += " " + self if fullphrase
    return article
  end  # article

  # Return the proper plural form of word (note: plurals in English are rife
  # with exceptions, so the following is likely incomplete and imperfect, so
  # use "irregular" to handle unencoded exceptions) --
  def pluralize( howmany = 2, irregular = nil)
    # Assert: Invoking object is a single-word string; argument howmany is
    #         typically an integer variable to distinguish "one" from "many";
    #         irregular is a mutating plural form (if such is not found in
    #         the iwords hash herein), e.g., "geese" instead of "gooses".
    return ( howmany != 1 ? irregular : word ) if irregular

    word = self.to_s
    wsym = self.to_sym
    # Mutated (irregular) forms:
    iwords = Hash.new
    iwords = { # exceptions to "...o" -> "...oes" here:
               piano: "pianos", zero: "zeros", pro: "pros", quarto: "quartos",
               photo: "photos", volcano: "volcanos", kimono: "kimonos",
               # other irregulars:
               person: "people", child: "children", woman: "women", man: "men",
               datum: "data", data: "data", index: "indices", matrix: "matrices",
               medium: "media", phenomenon: "phenomena", formula: "formulae",
               maximum: "maxima", minimum: "minima",
               nucleus: "nuclei", syllabus: "syllabi", nebula: "nebulae",
               basis: "bases", crisis: "crises", thesis: "theses",
               appendix: "appendices", focus: "foci", criterion: "criteria",
               life: "lives", fungus: "fungi", cactus: "cacti",
               mouse: "mice", goose: "geese", moose: "moose", deer: "deer",
               calf: "calves", leaf: "leaves", knife: "knives",
               foot: "feet", barracks: "barracks" }
    return iwords[wsym] if iwords[wsym]

    # "cherry" -> "cherries", "lady" -> "ladies",
    # but "day" -> "days" and "...key" -> "...keys"
    if ( word[-1] == "y" )      &&      # ends in "y",
       ( word[-2] =~ /[^aeiou]/ )       # and is not preceeded by a vowel
      return howmany != 1 ? word[0..-2] + "ies" : word
    end  # if ...

    # "kiss" -> "kisses", "box" -> "boxes", "potato" -> "potatoes",
    # "dish" -> "dishes", "witch" -> "witches",
    # but all other "word" -> "words"...
    s = ( word[-1]   == "s"  ||
          word[-1]   == "x"  ||
          word[-1]   == "o"  ||
          word[-2,2] == "sh" ||
          word[-2,2] == "ch"   ) ? "es" : "s"
    return howmany != 1 ? word + s : word
  end  # pluralize

  # Squeeze runs of whitespace down to single-blanks
  def compress( whitespace = " \t" )
    self.tr( whitespace, " " ).squeeze( " " ).strip
  end  # compress

  # Collapse runs of whitespace down to ""
  def collapse( whitespace = " \t" )
    pat = Regexp.new( "[#{whitespace}]" )
    self.gsub( pat, "" )
  end  #collapse

  # Convert a mode_human_readable(_VMS) string
  # back into an integer mode/permission value
  def to_mode
    # " O:rwx G:rwx W:rwx" => "rwxrwxrwx"
    # (also remove any directory, link, sticky-bit indicators)
    m = self.delete( " OGW:dlst" )
    # "r--r-xrwx" => "100101111" (binary bit-string)
    m.tr!( "rwx", "1" )  # set bits
    m.tr!( "-", "0" )    # clear bits
    return m.to_i(2)     # binary-string returned as integer
  end  # to_mode

  # Return the Nth (starting with 0) element from a delimited string
  def element( elno = 0, delimiter = "," )
    # returns "" (empty string) for non-existent elements
    self.split(delimiter)[elno]
  end  # element

  # Separate groups of characters with a separator
  def groupsep( grp = 3, sep = ",", decpt = '.' )
    num = self.to_s.strip
    if num.include?(decpt)
      nums = num.split(decpt)
      nums.delete_if { |n| n == "" }
      num = nums[0]
    end
    thou = []
    while num != ""
      ln  = num.length < grp ? num.length : grp
      tpl = num[-ln,grp]
      num[-ln,grp] = ""
      thou << tpl
    end  # while
    thou = thou.reverse.join(sep)
    if nums
      nums[0] = thou
      thou = nums.join(decpt)
    end
    return thou
  end  # groupsep

  # Separate a string (usually digits) into thousands --
  # e.g. "23456789" => "23,456,789"
  # (See Note above, and Numeric.thousands below...)
  def thousands( sep = "," )
    self.groupsep( 3, sep )
  end  # thousands

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
      e = editlist.downcase.element(i) || ""
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
