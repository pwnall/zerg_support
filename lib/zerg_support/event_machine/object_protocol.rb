require 'yaml'

#:nodoc: namespace
module Zerg::Support::EventMachine

# Event Machine protocol for sending serializable objects.
module ObjectProtocol
  include FrameProtocol

  # Send a serialized object.
  def send_object(object)
    send_frame YAML.dump(object)
  end
  
  #:nodoc: Processes an incoming frame and de-serializes the object in it.
  def receive_frame(frame_data)
    receive_object YAML.load(frame_data)
  end
  
  # Override to process incoming objects.
  def receive_object(object); end
end

end # namespace Zerg::Support::EventMachine
