#:nodoc: namespace
module Zerg::Support::Protocols
  
# Protocol for sending and receiving discrete-sized frames over TCP streams.
module FrameProtocol
  # Called when data is available from the TCP stream.
  def received_bytes(data)
    @frame_protocol_varsize ||= ''

    i = 0
    loop do
      while @frame_protocol_buffer.nil? and i < data.size
        @frame_protocol_varsize << data[i]
        if (data[i] & 0x80) == 0
          @frame_protocol_bytes_left =
              FrameProtocol.decode_natural @frame_protocol_varsize
          @frame_protocol_buffer = ''
        end
        i += 1
      end

      return if @frame_protocol_buffer.nil?
      break if @frame_protocol_bytes_left > data.size - i

      received_frame @frame_protocol_buffer + data[i, @frame_protocol_bytes_left]
      @frame_protocol_varsize, @frame_protocol_buffer = '', nil
      i += @frame_protocol_bytes_left
    end

    @frame_protocol_buffer << data[i..-1]
    @frame_protocol_bytes_left -= data.size-i
  end
  
  # Override to process incoming frames.
  def received_frame(frame_data); end

  # Sends a frame via the underlying TCP stream.
  def send_frame(frame_data)
    send_bytes FrameProtocol.encode_frame(frame_data)
  end
  
  # :nodoc: Encodes frame data into data to be sent across a TCP wire.
  def self.encode_frame(frame_data)
    encoded_length = FrameProtocol.encode_natural(frame_data.length)
    encoded_length + frame_data
  end

  #:nodoc: Encodes a natural (non-negative) integer into a string.
  def self.encode_natural(number)
    string = ''
    loop do
      number, byte = number.divmod(0x80)
      string << (byte | ((number > 0) ? 0x80 : 0x00))
      break if number == 0
    end
    string
  end
  
  #:nodoc: Decodes a natural (non-negative) integer from a string.
  def self.decode_natural(string)
    number = 0
    multiplier = 1
    string.each_byte do |byte|
      more, number_bits = byte.divmod 0x80
      number += number_bits * multiplier
      break if more == 0
      multiplier *= 0x80
    end
    return number
  end  
end

end  # namespace Zerg::Support::Protocols
