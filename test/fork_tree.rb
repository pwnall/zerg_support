# Used in test_process.rb to produce a tree of children.
# Usage:
#   ruby test/fork_tree.rb level interval cookie
# Arguments:
#   level - the fork level; 0 means don't fork, otherwise fork two children
#           with fork level-1
#   interval - the time to sleep (in seconds)
#   cookie - an argument that's preserved to help track down the process
#            also, the PID will be written to cookie.pid unless the file already
#            exists (this means that only the fork tree's root writes it)

require 'English'

# extract arguments
level = ARGV[1].to_i
interval = ARGV[2].to_f
cookie = ARGV[3]

# write PID file
pid_file = cookie + ".pid"
unless File.exist? pid_file
  File.open(pid_file, "w") { |f| f.write $PID.to_s }
end

# spawn children
unless level == 0
  2.times do
    Thread.new do
      system "ruby test/fork_tree.rb -- #{level - 1} #{interval} #{cookie}"
    end
  end 
end

sleep interval
