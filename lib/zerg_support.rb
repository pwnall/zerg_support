# :nodoc
module Zerg
end

# TODO(victor): document this
module Zerg::Support
end

require 'rubygems'
require 'zerg_support/gems.rb'
require 'zerg_support/process.rb'
require 'zerg_support/open_ssh.rb'
require 'zerg_support/spawn.rb'

# TODO(victor): document this
module Zerg::Support::EventMachine  
end

require 'zerg_support/event_machine/connection_mocks.rb'
require 'zerg_support/event_machine/frame_protocol.rb'
require 'zerg_support/event_machine/object_protocol.rb'
