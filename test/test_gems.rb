require 'digest/sha1'
require 'test/unit'

require 'zerg_support'

class TestGems < Test::Unit::TestCase
  def hash_gems_file
    file_path = File.join(File.dirname(__FILE__),
                          '../lib/zerg_support/gems.rb')
    Digest::SHA1.hexdigest File.read(file_path)
  end
  
  def test_source_is_manually_tested
    golden_hash = '21ba9ca1e8fa3aa205b468a884746eb37697df9b'
    source_hash = hash_gems_file
    
    assert_equal golden_hash, source_hash, <<END_MESSAGE
lib/zerg_support/zerg_support.rb has changed

You need to manually test the file, then replace golden_hash in this test.
Manual testing plan:
1. rake install this gem (zerg_support)
2. install zerg
3. validate that the installation does not crash and the binary gets symlinked
in the correct place
4. replace golden_hash with #{source_hash}
END_MESSAGE
  end
end