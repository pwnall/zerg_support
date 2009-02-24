require 'base64'
require 'openssl'

# Tools for managing openssh cryptographic material
module Zerg::Support::OpenSSH
  # Extracts the keys from a file of known_hosts format.  
  def self.known_hosts_keys(io)
    io.each_line do |line|
      
    end
  end
  
  # The components in a openssh .pub / known_host RSA public key.
  RSA_COMPONENTS = ['ssh-rsa', :e, :n]
  # The components in a openssh .pub / known_host DSA public key.
  DSA_COMPONENTS = ['ssh-dss', :p, :q, :g, :pub_key]

  # Encodes a key's public part in the format found in .pub & known_hosts files.
  def self.encode_pubkey(key)
    case key
    when OpenSSL::PKey::RSA
      components = RSA_COMPONENTS
    when OpenSSL::PKey::DSA
      components = DSA_COMPONENTS
    else
      raise "Unsupported key type #{key.class.name}"
    end
    components.map! { |c| c.kind_of?(Symbol) ? encode_mpi(key.send(c)) : c }
    # ruby tries to be helpful and adds new lines every 60 bytes :(
    [pack_pubkey_components(components)].pack('m').gsub("\n", '')
  end
  
  # Decodes an openssh public key from the format of .pub & known_hosts files.
  def self.decode_pubkey(string)
    components = unpack_pubkey_components Base64.decode64(string)
    case components.first
    when RSA_COMPONENTS.first
      ops = RSA_COMPONENTS.zip components
      key = OpenSSL::PKey::RSA.new
    when DSA_COMPONENTS.first
      ops = DSA_COMPONENTS.zip components
      key = OpenSSL::PKey::DSA.new
    else
      raise "Unsupported key type #{components.first}"
    end
    ops.each do |o|
      next unless o.first.kind_of? Symbol
      key.send "#{o.first}=", decode_mpi(o.last)
    end
    return key
  end

  # Loads a serialized key from an IO instance (File, StringIO).
  def self.load_key(io)
    key_from_string io.read
  end

  # Reads a serialized key from a string.
  def self.key_from_string(serialized_key)
    header = first_line serialized_key
    if header.index 'RSA'
      OpenSSL::PKey::RSA.new serialized_key
    elsif header.index 'DSA'
      OpenSSL::PKey::DSA.new serialized_key
    else
      raise 'Unknown key type'
    end
  end

  # Extracts the first line of a string.
  def self.first_line(string)
    string[0, string.index(/\r|\n/) || string.len]
  end  
  
  # Unpacks the string components in an openssh-encoded pubkey.
  def self.unpack_pubkey_components(str)
    cs = []
    i = 0
    while i < str.length
      len = str[i, 4].unpack('N').first
      cs << str[i + 4, len]
      i += 4 + len
    end
    return cs
  end
  
  # Packs string components into an openssh-encoded pubkey.
  def self.pack_pubkey_components(strings)
    (strings.map { |s| [s.length].pack('N') }).zip(strings).flatten.join
  end
  
  # Decodes an openssh-mpi-encoded integer.
  def self.decode_mpi(mpi_str)
    mpi_str.unpack('C*').inject(0) { |acc, c| (acc << 8) | c }
  end  
  
  # Encodes an openssh-mpi-encoded integer.
  def self.encode_mpi(n)
    chars, n = [], n.to_i
    chars << (n & 0xff) and n >>= 8 while n != 0
    chars << 0 if chars.empty? or chars.last >= 0x80
    chars.reverse.pack('C*')
  end  
end
