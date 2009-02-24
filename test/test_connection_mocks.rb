require 'test/unit'

require 'zerg_support'

require 'rubygems'
require 'flexmock/test_unit'

class HollowReceiveMock < Zerg::Support::EventMachine::ReceiveMock
end

# Collects groups of 3 letters, stores them into idenity hashes.
class ReceiveFooMock < Zerg::Support::EventMachine::ReceiveMock
  object_name :foo
  
  def receive_data(data)
    @s ||= ''
    data.each_byte do |c|
      @s << c
      if @s.length == 3
        receive_foo @s => @s
        @s = ''
      end
    end
  end
end

class ConnectionMocksTest < Test::Unit::TestCase
  def test_send_mock
    send_mock = Zerg::Support::EventMachine::SendMock.new    
    assert_equal send_mock.string, ''
    
    send_mock.send_data('a')
    assert_equal send_mock.string, 'a'

    send_mock.send_data('bcd')
    assert_equal send_mock.string, 'abcd'

    send_mock.send_data('em')
    assert_equal send_mock.string, 'abcdem'
  end
  
  def test_receive_mock_calls_recieve_data
    recv_mock = HollowReceiveMock.new ['a', 'bcd', 'em']
    flexmock(recv_mock).should_receive(:receive_data).with('a').once
    flexmock(recv_mock).should_receive(:receive_data).with('bcd').once
    flexmock(recv_mock).should_receive(:receive_data).with('em').once
    recv_mock.replay
  end
  
  def test_receive_mock_collects_objects
    foos = ReceiveFooMock.new(['a', 'bcd', 'emx']).replay.foos
    assert_equal [{'abc' => 'abc'}, {'dem' => 'dem'}], foos

    foos = ReceiveFooMock.new('ab').replay.foos
    assert_equal [], foos
  end
end