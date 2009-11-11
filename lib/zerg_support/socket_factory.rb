require 'socket'

# :nodoc: namespace
module Zerg::Support

module SocketFactory
  # Splits a host:port IP address into its components. IPv6 addresses welcome.
  #
  # The port will be nil if the IP address doesn't contain it.
  def self.split_address(address)
    port_match = /(^|[^:])\:([^:].*)$/.match(address)
    if port_match
      port = port_match[2]
      host = address[0, address.length - port.length - 1]
      [(host.empty? ? nil : host), port]
    else
      [address, nil]
    end
  end  
  
  # The host from a host:port IP address.
  #
  # Empty string if the IP address does not contain a host (e.g. :3000)
  def self.host_from_address(address)
    address and split_address(address)[0]
  end
  
  # The port from a host:port IP address.
  #
  # nil if the IP address does not contain a port (e.g. localhost)
  def self.port_from_address(address)
    address and (port_string = split_address(address)[1]) and port_string.to_i
  end

  # True for options requesting a connecting (as opposed to listening) socket.
  def self.outbound?(options)
    [:out_port, :out_host, :out_addr].any? { |k| options[k] }
  end
  
  # The host from a host:port IP address, in a form suitable for bind().
  def self.bind_host(options)
    host_from_address(options[:in_addr]) or options[:in_host] or '0.0.0.0'
  end
  
  # The port from a host:port IP address, in a form suitable for bind().
  def self.bind_port(options)
    port_from_address(options[:in_addr]) or options[:in_port] or 0
  end

  # An address suitable for bind() based on the options.
  def self.bind_socket_address(options)
    Socket::pack_sockaddr_in bind_port(options), bind_host(options)
  end

  # The host from a host:port IP address, in a form suitable for connect().
  def self.connect_host(options)
    options[:out_host] or host_from_address(options[:out_addr]) or 'localhost'
  end

  # The port from a host:port IP address, in a form suitable for connect().  
  def self.connect_port(options)
    port_from_address(options[:out_addr]) or options[:out_port]
  end
  
  # True if the options indicate TCP should be used, false for UDP.  
  def self.tcp?(options)
    options[:tcp] or !options[:udp]
  end

  # The socket() type based on the options.  
  def self.socket_type(options)
    tcp?(options) ? Socket::SOCK_STREAM : Socket::SOCK_DGRAM
  end
  
  # Sets socket flags (via setsockopt) based on the options.
  def self.set_options(socket, options)
    if options[:no_delay]
      if tcp?(options)
        socket.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true
      end
      socket.sync = true
    end
    
    if options[:reuse_addr]
      socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true
    end
    
    unless options[:reverse_lookup]
      if socket.respond_to? :do_not_reverse_lookup
        socket.do_not_reverse_lookup = true
      else
        # work around until the patch below actually gets committed:
        # http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/2346
        BasicSocket.do_not_reverse_lookup = true
      end
    end
    
    if options[:linger]
      socket.setsockopt Socket::SOL_SOCKET, Socket::SO_LINGER,
                        [1, options[:linger]].pack('ii')
    else
      # No lingering sockets.
      socket.setsockopt Socket::SOL_SOCKET, Socket::SO_LINGER, [1, 0].pack('ii')
      sugar_socket_close socket
    end
  end

  # Hacks a socket's accept method so that new sockets have the given flags set.
  #
  # The flags are set in a similar manner to set_options.
  def self.set_options_on_accept_sockets(socket, options)
    socket.instance_variable_set :@zerg_support_factory_options, options
    def socket.accept(*args)
      sock, addr = super
      Zerg::Support::SocketFactory.set_options sock,
                                               @zerg_support_factory_options
      return sock, addr
    end
  end
  
  # Sugar-coat the socket's listen() call with a default value for its argument.
  def self.sugar_socket_listen(socket)
    def socket.listen(*args)
      args = [1000] if args.empty?
      super(*args)
    end
  end

  # Sugar-coat the socket's close() call with the proper way to close a socket.
  def self.sugar_socket_close(socket)
    def socket.close
      shutdown rescue nil
      recv 1 rescue nil
      super
    end    
  end
  
  # Binds a socket to an address based on the options.
  def self.bind(socket, options)
    socket.bind bind_socket_address(options)    
    socket
  end
  
  # New inbound socket based on the options.
  def self.new_inbound_socket(options)
    socket = Socket.new Socket::AF_INET, socket_type(options), Socket::PF_UNSPEC
    set_options socket, options
    set_options_on_accept_sockets socket, options
    sugar_socket_listen socket
    bind socket, options    
  end
  
  # Retrieves possible IP addresses to connect to based on the given options.
  #
  # The retrieval is done via setsockopt.
  def self.addr_infos(options)
    Socket.getaddrinfo connect_host(options), connect_port(options),
                       Socket::AF_INET, socket_type(options)
  end  
  
  # New outbound socket based on an address obtained from getaddrinfo().
  def self.new_outbound_socket_with_addr_info(addr_info)
    Socket.new addr_info[4], addr_info[5], addr_info[6]
  end
  
  # Connects a socket to an address obtained from getaddrinfo().
  #
  # Returns the socket for success, or nil if the connection failed.
  def self.connect_with_addr_info(socket, addr_info)
    begin      
      socket.connect Socket.pack_sockaddr_in(addr_info[1], addr_info[3])
      socket
    rescue
      nil
    end    
  end

  # New outbound socket based on the options.
  def self.new_outbound_socket(options)
    addr_infos = self.addr_infos options
    addr_infos.each do |addr_info|
      socket = new_outbound_socket_with_addr_info addr_info
      set_options socket, options      
      return socket if connect_with_addr_info socket, addr_info
      socket.close rescue nil
    end
    nil
  end
  
  # Kitchen-sink socket creation method. The following options are supported:
  #   tcp:: forces the use of TCP (overrides the udp option)
  #   udp:: selects UDP (the default is TCP)
  #   out_port:: the port to connect an outgoing socket to
  #   out_host:: the host to connect an outgoing socket to
  #   out_addr:: the host:port address to connect an outgoing socket to; the
  #              host and port override out_port and out_host, which can be used
  #              in conjunction with out_addr to provide default values
  #   in_port:: the port to bind a listening socket to
  #   in_host:: the host to bind a listening socket to
  #   in_addr:: the host:port address to bind a listening socket to; the host
  #              and port override in_port and in_host, which can be used in
  #              conjunction with in_addr to provide default values
  #   no_delay:: disables Nagles' algorithm
  #   reuse_addr:: allows binding other sockets to this socket's address
  #   reverse_lookup:: enables reverse lookups on connections; this is the Ruby
  #                    default, but ZergSupport changes it for performance
  def self.socket(options)
    if outbound? options
      new_outbound_socket options
    else      
      new_inbound_socket options
    end
  end
end  # class SocketFactory

end  # namespace Zerg::Support
