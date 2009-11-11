require 'zerg_support'

require 'test/unit'

module FrameProtocolTestMethods
  FP = Zerg::Support::Protocols::FrameProtocol

  def setup
    super
    @send_mock = self.class::SendFramesMock.new    
  end
  
  def teardown
    super
  end

  def continuous_data_test(frames)
    truncated_data_test frames, []
  end
  
  def truncated_data_test(frames, sub_lengths)
    frames.each { |frame| @send_mock.send_frame frame }
    in_string = @send_mock.string
    in_strings, i = [], 0
    sub_lengths.each do |sublen|
      in_strings << in_string[i, sublen]
      i += sublen
    end
    in_strings << in_string[i..-1] if i < in_string.length
    out_frames =
        self.class::ReceiveFramesMock.new(@send_mock.string).replay.frames
    assert_equal frames, out_frames
  end

  def test_empty_frame
    continuous_data_test ['']
  end
  
  def test_byte_frame
    continuous_data_test ['F']
  end

  def test_string_frame
    continuous_data_test [(32...128).to_a.pack('C*')]
  end
  
  def test_multiple_frames
    continuous_data_test [(32...128).to_a.pack('C*'), '', 'F', '', '1234567890']
  end
  
  def test_truncated_border
    truncated_data_test ['A', 'A'], [1, 0, 2, 0]
  end
  
  def test_truncated_border_and_joined_data_size
    truncated_data_test ['A', 'A'], [1, 1, 1, 1]
  end
  
  def test_truncated_size
    long_frame = (32...128).to_a.pack('C*') * 5
    truncated_data_test [long_frame], [1]
  end

  def test_truncated_size_and_data
    long_frame = (32...128).to_a.pack('C*') * 5
    truncated_data_test [long_frame], [1, 16]
  end
  
  def test_badass
    # TODO(not_me): this test takes 4 seconds; replace with more targeted tests
    
    # build the badass string
    s2_frame = 'qwertyuiopasdfgh' * 8 * 128 # 16384 characters, size is 3 bytes
    @send_mock.send_frame s2_frame
    s2_string = @send_mock.string
    s2_count = 3
    send_string = s2_string * s2_count
    ex_frames = [s2_frame] * s2_count
    
    # build cut points in a string
    s2_points = [1, 2, 3, 4, 5, 127, 128, 8190, 16381, 16382, 16383]
    cut_points = []
    0.upto(s2_count - 1) do |i|
      cut_points += s2_points.map { |p| p + i * s2_string.length }
    end
    
    # try all combinations of cutting up the string in 4 pieces
    0.upto(cut_points.length - 1) do |i|
      (i + 1).upto(cut_points.length - 1) do |j|
        (j + 1).upto(cut_points.length - 1) do |k|
          packets = [0...cut_points[i], cut_points[i]...cut_points[j],
                     cut_points[j]...cut_points[k], cut_points[k]..-1].
                    map { |r| send_string[r] }
          assert_equal ex_frames,
              self.class::ReceiveFramesMock.new(packets).replay.frames
        end
      end
    end
  end  
  
  def test_natural_encoding
    table = [[0, "\0"], [1, "\x01"], [127, "\x7f"], [128, "\x80\x01"],
             [65535, "\xff\xff\x03"], [0xf0f0f0, "\xf0\xe1\xc3\x07"],
             [0xaa55aa55aa55, "\xd5\xd4\xd6\xd2\xda\xca\x2a"],
             [148296, "\310\206\t"]]
    table.each do |entry|
      assert_equal entry.last, FP.encode_natural(entry.first) 
      assert_equal entry.first, FP.decode_natural(entry.last) 
    end
  end  
end

class FrameProtocolEventMachineTest < Test::Unit::TestCase
  include FrameProtocolTestMethods
  
  ProtocolAdapter = Zerg::Support::EventMachine::ProtocolAdapter
  FP = Zerg::Support::Protocols::FrameProtocol
  FPAdapter = ProtocolAdapter.adapter_module FP
  
  # Send mock for frames.
  class SendFramesMock < Zerg::Support::EventMachine::SendMock
    include FPAdapter
  end

  # Receive mock for frames.
  class ReceiveFramesMock < Zerg::Support::EventMachine::ReceiveMock
    include FPAdapter
    object_name :frame
  end
end

class FrameProtocolSocketsTest < Test::Unit::TestCase
  include FrameProtocolTestMethods
  
  ProtocolAdapter = Zerg::Support::Sockets::ProtocolAdapter
  FP = Zerg::Support::Protocols::FrameProtocol
  FPAdapter = ProtocolAdapter.adapter_module FP
  
  # Send mock for frames.
  class SendFramesMock < Zerg::Support::Sockets::SendMock
    include FPAdapter
  end

  # Receive mock for frames.
  class ReceiveFramesMock < Zerg::Support::Sockets::ReceiveMock
    include FPAdapter
    object_name :frame
  end
end
