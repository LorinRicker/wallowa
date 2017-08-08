require 'pp'

pat = /\].*(\..*);/
extensions = Array.new
File.open( '/home/lorin/scratch/srcfile.lis', 'r' ).each_line do | f |
  if m = pat.match( f )
    extensions << m[1]
  end
end

unique = extensions.sort.uniq
pp unique

exit true
