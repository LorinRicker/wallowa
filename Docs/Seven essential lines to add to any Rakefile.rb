# Seven essential lines to add to any Rakefile
# ref: http://erniemiller.org/2014/02/05/7-lines-every-gems-rakefile-should-have

task :console do
  require 'irb'
  require 'irb/completion'
  require 'my_gem'   # You know what to do
  ARGV.clear
  IRB.start
end
