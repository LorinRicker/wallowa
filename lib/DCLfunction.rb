#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DCLfunction.rb
#
# Copyright © 2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 5.0, 08/21/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Common commands for DCL (dcl.rb)
#
# Used by ../projects/ruby/dcl.com and dclrename.rb

module DCLfunction

  # Conditional: needed only for these functional commands --
  require_relative '../lib/ppstrnum'
  require_relative '../lib/StringEnhancements'

# ==========

  def self.lexFunctions( action, operands, options )

    # Lexical Functions:
    case action.to_sym              # Dispatch the command-line action;
                                    # invoking symlink's name is $0 ...
    when :capcase
      ops = DCLfunction.getOps( operands, options )
      result = ops.capcase

    when :collapse
      ops = DCLfunction.getOps( operands, options )
      result = ops.collapse

    when :compress
      ops = DCLfunction.getOps( operands, options )
      result = ops.compress

    when :length
      ops = DCLfunction.getOps( operands, options )
      result = ops.length         # String class does this one directly

    when :locase, :lowercase
      ops = DCLfunction.getOps( operands, options )
      result = ops.locase         # String class does this one directly

    when :numbernames
      # $ numbernames number
      ops = DCLfunction.getOps( operands, options )
      # Stanza-per-line output:
      #    call as: ops.numbernames( '\n' )
      # for use as: $ echo -e $( numbernames <num> )
      result = ops.numbernames.split( ', ' )
      result.each { |s| $stdout.puts s }
      exit true

    when :thousands
      # $ thousands number
      ops = DCLfunction.getOps( operands, options )
      result = ops.thousands

    when :titlecase
      ops = DCLfunction.getOps( operands, options )
      result = ops.titlecase

    when :trim
      ops = DCLfunction.getOps( operands, options )
      result = ops.strip          # String class does this one directly

    when :trim_leading
      ops = DCLfunction.getOps( operands, options )
      result = ops.lstrip         # String class does this one directly

    when :trim_trailing
      ops = DCLfunction.getOps( operands, options )
      result = ops.rstrip         # String class does this one directly

    when :uncomment
      ops = DCLfunction.getOps( operands, options )
      result = ops.uncomment

    when :upcase, :uppercase
      ops = DCLfunction.getOps( operands, options )
      result = ops.upcase         # String class does this one directly

    # when :«+»
    #   ops = DCLfunction.getOps( operands, options )
    #   result = ops.«+»

    when :cjust
      # $ cjust width "String to center-justify..."
      ## >> How to default width to terminal-width, and how to specify padchr? Syntax?
      width  = operands.shift.to_i
      # padchr = operands.shift
      ops = DCLfunction.getOps( operands, options )
      result = ops.center( width )

    when :ljust
      # $ ljust width "String to center-justify..."
      width  = operands.shift.to_i
      # padchr = operands.shift
      ops = DCLfunction.getOps( operands, options )
      result = ops.ljust( width )

    when :rjust
      # $ rjust width "String to center-justify..."
      width  = operands.shift.to_i
      # padchr = operands.shift
      ops = DCLfunction.getOps( operands, options )
      result = ops.rjust( width )

    when :edit
      # $ edit "func1,func2[,...]" "String to filter"
      #   where "func1,funct2[,...]" -- the editlist -- is required
      editlist = operands.shift            # assign and remove arg [0]
      ops = DCLfunction.getOps( operands, options )
      result = ops.edit( editlist, '#' )   # assume bash-style comments

    when :element
      # $ element 2 [","] "String,to,extract,an,element,from:
      #   where first arg is the element-number (zero-based) to extract,
      #   and second arg is (optional) element separator (default ",");
      #   note that if length of second arg is > 1, it defaults, and
      #   remainder of string is the string to filter
      elem = operands.shift.to_i                             # assign and remove arg [0]
      sep  = operands[0].length == 1 ? operands.shift : ","  # and arg [1]
      ops = DCLfunction.getOps( operands, options )
      result = ops.element( elem, sep )

    when :pluralize
      # $ pluralize word howmany [irregular]
      word      = operands.shift                  # assign and remove arg [0]
      howmany   = operands.shift.to_i             # and arg [1]
      irregular = ops[0] ? operands.shift : nil   # and (optional) arg [2]
      # ops = DCLfunction.getOps( operands, options )         # ...ignore rest of com-line
      result = word.pluralize( howmany, irregular )

    when :substr, :extract
      # $ substr start len "String to extract/substring from..."
      start = operands.shift.to_i
      len   = operands.shift.to_i
      ops  = DCLfunction.getOps( operands, options )
      result = ops[start,len]      # String class does this one directly

    when :dclsymlink
      # $ dclsymlink action [action]...
      dclsymlink( ops )            # Set &/or verify this action verb symlink
      exit true

    else
      $stderr.puts "%#{PROGNAME}-e-nyi, DCL function '#{action}' not yet implemented"
      exit false

    end  # case action.to_sym

    if options[:verbose]
      $stderr.puts "%#{PROGNAME}-I-echo,   $ " + "#{action}".underline + " '#{ops}'"
      $stderr.puts "%#{PROGNAME}-I-result, " + "'#{result}'".bold
    end  # if options[:verbose]

    $stdout.print result  # Print filtered result to std-output
  end  # lexFunctions

# ==========

private

  def self.getOps( operands, options )
    ops = ''
    if operands[0]
      ops = operands.join( " " )           # All operands into one big sentence...
    else                                   # ...or from std-input
      ops = $stdin.readline.chomp if !options[:symlinks]
    end  # if operands[0]
    return ops
  end  # getOps

end  # module DCLfunction
