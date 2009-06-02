# :nodoc: namespace
module Zerg::Support::Sockets

# Mocks the sending end of a Socket connection.
# The sent data is concatenated in a string available by calling #string.
class SendMock  
  attr_reader :string
  
  def initialize
    @string = ''
  end
  
  def send(data, flags)
    @string << data
  end
end  # class SendMock

# Mocks the receiving end of a Socket connection.
# The data to be received is passed as an array of strings to the constructor.
class ReceiveMock
  attr_accessor :strings
  attr_accessor :objects
  
  def initialize(strings = [''])
    @strings = strings.kind_of?(String) ? [strings] : strings
    @objects = []
  end
  
  def recv(byte_limit)
    bytes = @strings.shift
    return '' unless bytes
    if bytes.length > byte_limit
      @strings.unshift bytes[byte_limit, bytes.length]
      bytes = bytes[0, byte_limit]
    end
    bytes
  end
  
  # Declares the name of the object to be received. For instance, a frame
  # protocol would use :frame for name. This generates a receive_frame method,
  # and a frames accessor.
  def self.object_name(name)
    # Calls recv_object until the bytes buffer is drained.
    define_method :replay do
      while @strings.length > 0
        @objects << self.send(:"recv_#{name}")
      end
      loop do
        object = self.send(:"recv_#{name}")
        break unless object
        @objects << object
      end
      self
    end
    return if name == :object
    alias_method :"#{name}s", :objects
  end  
end  # class ReceiveMock

end  # namespace Zerg::Support::Sockets
