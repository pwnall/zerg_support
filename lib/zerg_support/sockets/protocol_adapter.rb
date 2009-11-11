# :nodoc: namespace
module Zerg::Support::Sockets

# Adapts generic Protocol modules to modules that can extend sockets.
module ProtocolAdapter
  def self.adapter_module(protocol_module, object_name = nil)    
    unless object_name
      object_name = /(^|:)([^:]*)Protocol$/.
          match(protocol_module.name)[2].split(/(?=[A-Z])/).join('_').downcase
    end
    
    state_class = Class.new StateBase
    state_class.send :include, protocol_module
    state_class.class_eval do
      # Called by the protocol when an entire object is available.
      define_method :"received_#{object_name}" do |object|
        @recv_object_buffer << object
      end
    end
    
    adapter = Module.new
    adapter.module_eval do
      # Receives an object from a socket.
      define_method :"recv_#{object_name}" do
        @zerg_protocol_adapter_state ||= state_class.new self
        while @zerg_protocol_adapter_state.recv_object_buffer.empty?
          begin
            data = recv 65536
          rescue SystemCallError  # The other side closed the socket forcibly.
            break
          end
          break if data.empty?  # The other side closed the socket.

          @zerg_protocol_adapter_state.received_bytes data
        end
        @zerg_protocol_adapter_state.recv_object_buffer.shift
      end

      # Sends an object across a socket.
      define_method :"send_#{object_name}" do |object|
        @zerg_protocol_adapter_state ||= state_class.new self
        @zerg_protocol_adapter_state.send :"send_#{object_name}", object
      end
    end
    
    adapter
  end
  
  # Base class for the adapter state.
  class StateBase
    attr_reader :recv_object_buffer
    def initialize(target)
      @recv_object_buffer = []
      @target = target
    end

    # Called by the protocol when an entire object is available.
    def send_bytes(data)
      # NOTE: need to chunk the data so kernel buffers don't overflow.
      #       Found out about this the hard way -- sending 150k in one call
      #       drops data.      
      i = 0
      while i < data.length      
        @target.send data[i, 65536], 0
        i += 65536
      end
    end
  end
end

end  # namespace Zerg::Support::Sockets
