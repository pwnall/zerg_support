require 'test/unit'

require 'zerg_support'


class SocketFactoryTest < Test::Unit::TestCase
  SF = Zerg::Support::SocketFactory
  
  OP = Zerg::Support::Protocols::ObjectProtocol
  OPAdapter = Zerg::Support::Sockets::ProtocolAdapter.adapter_module OP
  
  def setup
    super
    @thread_abort = Thread.abort_on_exception
    Thread.abort_on_exception = true
  end

  def teardown
    Thread.abort_on_exception = @thread_abort
    super    
  end
  
  def test_host_from_address
    assert_equal nil, SF.host_from_address(nil)
    assert_equal nil, SF.host_from_address(':9000')
    assert_equal '127.0.0.1', SF.host_from_address('127.0.0.1')
    assert_equal '127.0.0.1', SF.host_from_address('127.0.0.1:1234')
    assert_equal 'fe80::1%lo0', SF.host_from_address('fe80::1%lo0')
    assert_equal 'fe80::1%lo0', SF.host_from_address('fe80::1%lo0:19020')
  end
  
  def test_port_from_address
    assert_equal nil, SF.port_from_address(nil)
    assert_equal 9000, SF.port_from_address(':9000')
    assert_equal nil, SF.port_from_address('127.0.0.1')
    assert_equal 1234, SF.port_from_address('127.0.0.1:1234')
    assert_equal nil, SF.port_from_address('fe80::1%lo0')
    assert_equal 19020, SF.port_from_address('fe80::1%lo0:19020')
  end
  
  def test_inbound
    assert !SF.outbound?(:in_port => 1)
    assert !SF.outbound?(:in_host => '1')
    assert !SF.outbound?(:in_addr => '1')
    assert SF.outbound?(:out_port => 1)
    assert SF.outbound?(:out_host => '1')
    assert SF.outbound?(:out_addr => '1')
  end
  
  def test_tcp
    assert SF.tcp?({})
    assert SF.tcp?(:tcp => true)
    assert !SF.tcp?(:udp => true)
  end
  
  def _test_connection(server_options, client_options = nil)
    client_options ||= server_options
    test_port = 31996
    
    cli_gold = { :request_type => 1, :request_name => "moo",
                 :blob => 'abc' * 43000 }
    srv_gold = { :response_type => 2, :response_value => [true, 314],
                 :rblob => 'xyz' * 41000 }
    cli_hash = nil
    
    # Server thread.
    server = SF.socket({:in_addr => ":#{test_port}"}.merge server_options)
    Thread.new do
      server.listen
      serv_client, client_addrinfo = server.accept
      serv_client.extend OPAdapter
      cli_hash = serv_client.recv_object
      serv_client.send_object srv_gold
      serv_client.close
    end
    
    # Client.
    client = SF.socket({:out_addr => "localhost:#{test_port}"}.
                       merge(client_options))
    client.extend OPAdapter
    client.send_object cli_gold
    srv_hash = client.recv_object
    client.close
    server.close
    
    # Checks
    assert_equal cli_gold, cli_hash, "Client -> server failed"
    assert_equal srv_gold, srv_hash, "Server -> client failed"
  end
  
  def test_connection  
    _test_connection({:no_delay => true})
    _test_connection({:reuse_addr => true})
    
    # TODO(costan): fix UDP at some point
  end
end
