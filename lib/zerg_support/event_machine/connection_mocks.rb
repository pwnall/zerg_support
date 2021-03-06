# :nodoc: namespace
module Zerg::Support::EventMachine

# Mocks the sending end of an EventMachine connection.
# The sent data is concatenated in a string available by calling #string.
class SendMock  
  attr_reader :string
  
  def initialize
    @string = ''
  end
  
  def send_data(data)
    @string << data
  end
end  # class SendMock

# Mocks the receiving end of an EventMachine connection.
# The data to be received is passed as an array of strings to the constructor.
# Calling #replay mocks receiving the data.
class ReceiveMock
  attr_accessor :strings
  attr_accessor :objects
  
  def initialize(strings = [''])
    @strings = strings.kind_of?(String) ? [strings] : strings
    @objects = []
  end
  
  # Simulates receiving all the given strings as data from Event Machine.
  def replay
    @strings.each { |str| receive_data str }
    self
  end

  # Declares the name of the object to be received. For instance, a frame
  # protocol would use :frame for name. This generates a receive_frame method,
  # and a frames accessor.
  def self.object_name(name)
    define_method(:"receive_#{name}") { |object| @objects << object }
    return if name == :object
    alias_method :"#{name}s", :objects
  end
end  # class ReceiveMock

end  # namespace Zerg::Support::EventMachine
