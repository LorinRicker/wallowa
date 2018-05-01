#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# prompted_loop_ex.rb
#   Generated as a quick-sample/example for a StackOverflow question
#

def process( emp, pay )
  pp emp, pay
end # process

loop do
  puts "Employee name (<Enter> to quit): "
  emp1 = STDIN.gets.chomp!
  break if emp1 == "" || emp1.nil?
  puts "Pay scale: "
  pay1 = STDIN.gets.chomp!
  process( emp1, pay1 )
  end

exit true
