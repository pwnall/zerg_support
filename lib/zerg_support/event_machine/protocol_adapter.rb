# :nodoc: namespace
module Zerg::Support::EventMachine

# Adapts generic Protocol modules for easy inclusion in EventMachine connection
# classes / modules.
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
        @target.send :"receive_#{object_name}", object
      end
    end
    
    adapter = Module.new
    adapter.module_eval do
      # Called by Event Machine when TCP stream data is available.
      define_method :receive_data do |data|
        @zerg_protocol_adapter_state ||= state_class.new self
        @zerg_protocol_adapter_state.received_bytes data
      end

      # Called by the Event Machine user to send data.
      define_method :"send_#{object_name}" do |object|
        @zerg_protocol_adapter_state ||= state_class.new self
        @zerg_protocol_adapter_state.send :"send_#{object_name}", object
      end
    end
    
    adapter
  end
  
  # Base class for the adapter state.
  class StateBase
    def initialize(target)
      @target = target
    end

    # Called by the protocol when an entire object is available.
    def send_bytes(data)
      @target.send_data data
    end
  end
end

end  # namespace Zerg::Support::EventMachine
