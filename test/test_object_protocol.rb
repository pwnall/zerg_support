require 'test/unit'

require 'zerg_support'

class ObjectProtocolTest < Test::Unit::TestCase
  OP = Zerg::Support::EventMachine::ObjectProtocol
  
  class SendObjectMock < Zerg::Support::EventMachine::SendMock
    include OP
  end
  class ReceiveObjectMock < Zerg::Support::EventMachine::ReceiveMock
    include OP
    object_name :object
  end
  
  def one_test(*objects)
    send_mock = SendObjectMock.new
    objects.each { |o| send_mock.send_object o }
    assert_equal objects, ReceiveObjectMock.new(send_mock.string).replay.objects
  end
  
  def test_border_cases
    one_test({})
    one_test(nil)
    one_test('')
    one_test(false)
    one_test(0)
    one_test([])
  end
  
  def test_literals
    one_test(1)
    one_test(true)
    one_test('A')
    one_test("A\nB\nC\tD")
  end
  
  def test_arrays
    one_test(['A'])
    one_test(['B', 'C'])
    one_test([0, 'C', [9, 'e'], true])
  end
  
  def test_hashes
    one_test({:command => 'run', :binary => '/bin/sh', :quick => false})
    one_test({:command => 'run', :args => { :key => 'v3', :log => true}})
  end
  
  def test_multiple_nested
    one_test({:command => 'init', :user => "m\0e", :key => false },
             {:command => 'package', :map => {'dir' => 1, 'NA' => true} },
             "1234567890",
             {:command => 'run', :sequence => [1, nil, 2, true, "Q\n"]})
  end
end