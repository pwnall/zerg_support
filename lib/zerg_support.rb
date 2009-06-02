# :nodoc: namespace
module Zerg
end

# TODO(victor): document this
module Zerg::Support
end

require 'rubygems'
require 'zerg_support/gems.rb'
require 'zerg_support/process.rb'
require 'zerg_support/open_ssh.rb'
require 'zerg_support/socket_factory.rb'
require 'zerg_support/spawn.rb'
require 'zerg_support/event_machine/connection_mocks.rb'
require 'zerg_support/event_machine/protocol_adapter.rb'
require 'zerg_support/protocols/frame_protocol.rb'
require 'zerg_support/protocols/object_protocol.rb'
require 'zerg_support/sockets/protocol_adapter.rb'
require 'zerg_support/sockets/socket_mocks.rb'
