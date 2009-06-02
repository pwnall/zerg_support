require 'yaml'

#:nodoc: namespace
module Zerg::Support::Protocols

# Event Machine protocol for sending serializable objects.
module ObjectProtocol
  include FrameProtocol

  # Send a serialized object.
  def send_object(object)
    send_frame YAML.dump(object)
  end
  
  #:nodoc: Processes an incoming frame and de-serializes the object in it.
  def received_frame(frame_data)
    received_object YAML.load(frame_data)
  end
  
  # Override to process incoming objects.
  def received_object(object); end
end

end  # namespace Zerg::Support::Protocols
