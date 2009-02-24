require 'zerg_support'

require 'test/unit'

module OpenSSHData; end

class OpenSshTest < Test::Unit::TestCase
  include OpenSSHData
  OpenSSH = Zerg::Support::OpenSSH

  def setup
    @rsa_key = OpenSSH.load_key StringIO.new(obsidian_rsa_privkey)
    @dsa_key = OpenSSH.load_key StringIO.new(obsidian_dsa_privkey)
  end
  
  @@mpi_test_table = [[0, "\0"], [0x80, "\0\x80"], [0x1234, "\x12\x34"],
                      [0xAA55, "\0\xAA\x55"]]
  def test_encode_mpi
    @@mpi_test_table.each {|e| assert_equal e.last, OpenSSH.encode_mpi(e.first) }
  end
  
  def test_decode_mpi
    @@mpi_test_table.each {|e| assert_equal e.first, OpenSSH.decode_mpi(e.last) }
  end

  @@pubkey_pack_table =  [[[], ''], [[''], "\0\0\0\0"],
                          [['A'], "\0\0\0\1A"],
                          [['A', 'BC'], "\0\0\0\1A\0\0\0\2BC"]]
  
  def test_pack_pubkey_components
    @@pubkey_pack_table.each do |e|
      assert_equal e.last, OpenSSH.pack_pubkey_components(e.first)
    end    
  end
  
  def test_unpack_pubkey_components
    @@pubkey_pack_table.each do |e|
      assert_equal e.first, OpenSSH.unpack_pubkey_components(e.last)
    end
  end
  
  def test_load_key
    assert_equal obsidian_rsa_privkey, @rsa_key.to_pem
    assert_equal obsidian_dsa_privkey, @dsa_key.to_pem
  end
  
  def test_encode_pubkey
    assert_equal obsidian_rsa_pubkey, OpenSSH.encode_pubkey(@rsa_key)
    assert_equal obsidian_dsa_pubkey, OpenSSH.encode_pubkey(@dsa_key)
  end
  
  def test_decode_pubkey
    assert_equal @rsa_key.public_key.to_pem,
                 OpenSSH.decode_pubkey(obsidian_rsa_pubkey).to_pem
    assert_equal @dsa_key.public_key.to_pem,
                 OpenSSH.decode_pubkey(obsidian_dsa_pubkey).to_pem
  end
end

module OpenSSHData
  def known_hosts_file
    <<END_KH
github.com,65.74.177.129 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
obsidian.local ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq7VciLo2wB+/2ThHXejC/kgkN205zlyS5cvN40Mqi3qvRVS75X1RawDoLot8eJ9KCYqZFr2Dr73d/EQNltN7dKJoPIj1IKxoraWkyNFbhhzpYuOltg9oO5UBSTNLupqla7zcdj4IwCCkBYk4+TS0dwmi20buOJ0FPY5PgbzmMnUiV9ipBqeJSdZB+TePH1gqlt7AP/6ti/0gxb2K7F69dZl/BSxMEzRCfBlTFC3f/4n8IdCuSJvNxxY+TtRnLL5CKUhj9QaIBan6JCkdRvVOBY7wmsNT8nGDzfDFSDD3KKn93g4LRkyMeaYlSDLxKy8PnNhjWgBNH1YNYyicsGfBKQ==
rubyforge.org,205.234.109.19 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3tPhdPUFGAYyrT1quRSOevLbAdKAJ6Ovwqw0m99R0QkqUwMUh09pgedWZeij7HtAHtoWPrNFev8FrwcwnL14NgA/gwNnXxbqd4twC1HyFShUf7POry8bz3Qk+84STHeMY8++hhn8LgNyfuVQswHoW661aqieLM6pF8q8xIUtkXA7daNpJAL4nTN1TxgUoCDpCa0EbUPkGpwFPNtGPuokRXNOCR9g8T6LmPQbzGUTc4CzFfQ9rrHaimqkEmRWJbBOaik1bdQNqOh6MUDDuUSpkJV7fwu3bl4fF5/1kw2HCREEjJmESOYnZhOS+MCp1qAUcuXqpMqXD8ATNsuXqrIhTQ==
END_KH
  end

  def obsidian_rsa_pubkey
    'AAAAB3NzaC1yc2EAAAABIwAAAQEAq7VciLo2wB+/2ThHXejC/kgkN205zlyS5cvN40Mqi3qvRVS75X1RawDoLot8eJ9KCYqZFr2Dr73d/EQNltN7dKJoPIj1IKxoraWkyNFbhhzpYuOltg9oO5UBSTNLupqla7zcdj4IwCCkBYk4+TS0dwmi20buOJ0FPY5PgbzmMnUiV9ipBqeJSdZB+TePH1gqlt7AP/6ti/0gxb2K7F69dZl/BSxMEzRCfBlTFC3f/4n8IdCuSJvNxxY+TtRnLL5CKUhj9QaIBan6JCkdRvVOBY7wmsNT8nGDzfDFSDD3KKn93g4LRkyMeaYlSDLxKy8PnNhjWgBNH1YNYyicsGfBKQ=='
  end
  
  def obsidian_dsa_pubkey
    'AAAAB3NzaC1kc3MAAACBAPdWp4HhWUoNawosyEBvrhPSbjhCJiKnVWiUS6bo0BCGzTHhugrkv2HgtlKhWo8nqTw5E4YxzFVyZ0YQt4m7NYDLTZVjrqbIpL/3F5qNXco127O/im0cG27AKC8Jf7knmUTjd8EBhtK65tNDmxPtzKQtemlNTVPX1VccOn6eLtn1AAAAFQDtQC21TJrf/p5WNsU9UIJzO9/hIwAAAIEAgwTrIfleQMEAK9N3xeMVZpAGfSAoX6owLtk3z+iQ3rM9FRvM/CgezOgezLowJghkw/bcQDmMuudBUuijrM3zZWdr6eqoNbFTR/KKiUx3cYf0LAHNPbXfVz+P7BXqjcEj75qnwuHQMp7vNMg+dmV40UA2TiC5/8QlaZVwkOSPN6gAAACAPMGJEFkoR0ayfkd0S/tnY9ilO17T6rdoDuF25ATtNUd6Zji6tslxBkQFWtTeinO3rGkqJRPndq0wp3E33AOHhJE/FOIlWl4Tf6aeU95Y4enYujKQDiImSTXmdiw5wq/LFdc3a2waOUvuI+647wxgHhqTmD7xI2biGZLYN9Oasy0='    
  end

  def obsidian_rsa_privkey
    <<END_RSAK
-----BEGIN RSA PRIVATE KEY-----
MIIEoQIBAAKCAQEAq7VciLo2wB+/2ThHXejC/kgkN205zlyS5cvN40Mqi3qvRVS7
5X1RawDoLot8eJ9KCYqZFr2Dr73d/EQNltN7dKJoPIj1IKxoraWkyNFbhhzpYuOl
tg9oO5UBSTNLupqla7zcdj4IwCCkBYk4+TS0dwmi20buOJ0FPY5PgbzmMnUiV9ip
BqeJSdZB+TePH1gqlt7AP/6ti/0gxb2K7F69dZl/BSxMEzRCfBlTFC3f/4n8IdCu
SJvNxxY+TtRnLL5CKUhj9QaIBan6JCkdRvVOBY7wmsNT8nGDzfDFSDD3KKn93g4L
RkyMeaYlSDLxKy8PnNhjWgBNH1YNYyicsGfBKQIBIwKCAQA/xwUc13Nr7okWKtit
2hyKVU9HyXve7y8/aPSzf1jx+l5blIBN7LfXSXrPdaNCvtJbULyEygxXN+S8yNHY
73b/b4XNV3D9gd281x/y0WsjL09fPpyitUP435LDatL8Ks+6TXZ1D7obedaFtqAi
DEMHpH5Rch33xUsW3RY3gK1F8GHzYh+zMd0llH8w6IVBv0hrWttyp+4By1dhXA3L
alYYOlGbu5cNuJfz50v4T/uB9F63JqHtAxEjqD7SvjCUbogGPxEH1k4Or+3xGuvR
yTPaiuR9kehBstjbqc91rTLnGOr5a1VUIq6++0tCVOXQa+x5J5zCu/baGTdfkgRU
loILAoGBAOHQcGIEgD1xHwFX9AafarF+1j4pPkM1p2u+9DNTIl1f2Rk6yOHlHZGF
mfozMyh6l4HpvPTT7nflM4YR0JWJNbQIpCY8CdYKMXBVWcH4PXuqwyGKJBZMXWkn
hKvelJ0UZUwx5+n8fTmSxLcIIlz5uKEE5k23/3cKkP7P6+Z6YuIZAoGBAMKpYBkM
A4JMJ3QJ5TVsdFOoO0b1wThRgQTZR6ic9rNeXnZiL0mmr44DX2T1rTnEm6KZv2f2
kWLQp5jx8BPFI+TUv16j4xrnnuHPhuBordCYQizSPcxXqL8b8a/KU+S5xofRjwB6
+8szd/JmGFDY8WgWrtIL32TdRhcIFg0Dg1mRAoGAE1sCUYtbcvsRSUINmirr41QD
vC9rvJ4y6/pss/Eu1M2zhdHWtEbWphLEDiGlTJzLKGR96Rl61xOlVKJw9t/gCB3/
cP3U9RbRCaDqb7YxJ9tvz6zBQ71nF6RNM02XtbFKgt+0yunBlzh3QuNwqOI0ZZK0
p5Ntqx4pr3DoVZV2MKMCgYBprGdeDdYE54MhvDqZWCHkRWIB8x+/fLPAzbkvpap+
oPFzdyD8GKhxqg82zoKbs991hqm8GCMJwboRMuFp0WtBtVHxjCrUF1ZAEZJckJje
85GjTY9DCwPVdZHUdSY6VjiS33mD6v23c7YkgJDbbnRrtIrJy+5MsqJkRjfbLcr2
GwKBgQCWDKVM8mZJcmM3KJwzBWh+b5T7tIbOBFaCvOBq4G0UUZGytWVUaddSbdh5
YJ+1CoLDB+Wp3U95B1USQuSYwwr0wOYy42HBII7HnkaphT9HgDIhgvttFhX162oC
bRizr31NgiGtgJbHJ9QPhaLvn3mZtZAFfRaEEdZslUzqRSACww==
-----END RSA PRIVATE KEY-----
END_RSAK
  end

  def obsidian_dsa_privkey
    <<END_DSAK
-----BEGIN DSA PRIVATE KEY-----
MIIBvAIBAAKBgQD3VqeB4VlKDWsKLMhAb64T0m44QiYip1VolEum6NAQhs0x4boK
5L9h4LZSoVqPJ6k8OROGMcxVcmdGELeJuzWAy02VY66myKS/9xeajV3KNduzv4pt
HBtuwCgvCX+5J5lE43fBAYbSuubTQ5sT7cykLXppTU1T19VXHDp+ni7Z9QIVAO1A
LbVMmt/+nlY2xT1QgnM73+EjAoGBAIME6yH5XkDBACvTd8XjFWaQBn0gKF+qMC7Z
N8/okN6zPRUbzPwoHszoHsy6MCYIZMP23EA5jLrnQVLoo6zN82Vna+nqqDWxU0fy
iolMd3GH9CwBzT2131c/j+wV6o3BI++ap8Lh0DKe7zTIPnZleNFANk4guf/EJWmV
cJDkjzeoAoGAPMGJEFkoR0ayfkd0S/tnY9ilO17T6rdoDuF25ATtNUd6Zji6tslx
BkQFWtTeinO3rGkqJRPndq0wp3E33AOHhJE/FOIlWl4Tf6aeU95Y4enYujKQDiIm
STXmdiw5wq/LFdc3a2waOUvuI+647wxgHhqTmD7xI2biGZLYN9Oasy0CFQDL/9Z1
fSLn88m1sUeWAZ4Ys2IIxw==
-----END DSA PRIVATE KEY-----
END_DSAK
  end
end
