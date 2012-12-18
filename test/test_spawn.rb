require 'digest/sha1'
require 'test/unit'

require 'zerg_support'

require 'rubygems'
require 'flexmock/test_unit'

class TestSpawn < Test::Unit::TestCase
  def temp_file
    now_cookie = "zerg_test_#{Time.now.to_f}s"
    File.open(now_cookie, 'w') {}
    return now_cookie
  end

  def setup
    super
    Thread.abort_on_exception = true
    @in_file = temp_file
    @out_file = temp_file
  end

  def teardown
    File.delete @in_file rescue nil
    File.delete @out_file rescue nil
    super
  end

  def test_stdout_redirect
    pid = Zerg::Support::Process.spawn 'ruby', ['-e', 'print "1234\n"'],
        STDOUT => @out_file
    Process.waitpid pid

    assert_equal "1234\n", File.read(@out_file)
  end

  def test_stdin_redirect
    File.open(@in_file, 'w') { |f| f.write "1234\n" }

    pid = Zerg::Support::Process.spawn 'ruby', ['-e', "print gets"],
        STDIN => @in_file, STDOUT => @out_file
    Process.waitpid pid
    assert_equal "1234\n", File.read(@out_file)
  end

  def test_stderr_redirect
    pid = Zerg::Support::Process.spawn 'ruby', ['-e', "raise 'zerg_stderr'"],
        STDERR => @out_file
    Process.waitpid pid
    assert_match(/zerg_stderr \(RuntimeError\)/m, File.read(@out_file))
  end

  def test_redirect_cascade
    pid = Zerg::Support::Process.spawn 'ruby',
                                       ['-e', "print 1; raise 'zerg_stderr'"],
        STDOUT => @out_file, STDERR => STDOUT
    Process.waitpid pid
    assert_match(/zerg_stderr \(RuntimeError\)/m, File.read(@out_file))
    assert_match(/1\n/m, File.read(@out_file))
  end

  def test_redirect_share
    pid = Zerg::Support::Process.spawn 'ruby',
                                       ['-e', "print 1; raise 'zerg_stderr'"],
        STDOUT => @out_file, STDERR => @out_file
    Process.waitpid pid
    assert_match(/zerg_stderr \(RuntimeError\)/m, File.read(@out_file))
    assert_match(/1/, File.read(@out_file))
    assert_no_match(/1\n/m, File.read(@out_file))
  end

  def test_async
    t0 = Time.now
    pid = Zerg::Support::Process.spawn 'ruby', ['-e', 'sleep 0.5']
    t1 = Time.now
    Process.waitpid pid
    t2 = Time.now

    assert_operator t1 - t0, :<, 0.2, 'Spawning is not asynchronous'
    assert_operator t2 - t0, :>, 0.5,
                    'The spawned program did not sleep for 1 second'
  end

  def test_set_environment
    pid = Zerg::Support::Process.spawn 'ruby', ['-e', 'print ENV[\'XA\']'],
        STDOUT => @out_file, :env => {'XA' => "1234\n"}
    Process.waitpid pid
    assert_equal "1234\n", File.read(@out_file)

    pid = Zerg::Support::Process.spawn 'ruby', ['-e', 'print ENV[\'PATH\']'],
        STDOUT => @in_file, :env => {'XA' => "1234\n"}, :unsetenv_others => true
    Process.waitpid pid
    # clearing the environment will reset PATH, so ruby might not run at all
    output = File.read(@in_file)
    assert output == 'nil' || output == '', 'The environment was not cleared'
  end

  def test_close_fd
    in_file = File.open(@in_file, 'w')
    in_file.sync = true
    in_file.write "1234\n"
    in_file.close

    in_file = File.open(@in_file, 'r')

    in_fd = in_file.fileno
    read_fd_code = "File.open(#{in_fd}).read"
    assert_equal "1234\n", eval(read_fd_code), 'File reading code is broken'

    pid = Zerg::Support::Process.spawn 'ruby', ['-e', "print #{read_fd_code}"],
        STDOUT => @out_file, STDERR => STDOUT
    Process.waitpid pid
    in_file.close

    assert_match(/^\-e\:1\:/, File.read(@out_file)[0, 5],
                 'Spawn does not close file descriptors')
  end

  def test_rlimit_processing
    if RUBY_PLATFORM =~ /win/ and RUBY_PLATFORM !~ /darwin/
      Process.const_set :RLIMIT_CPU, 'rlimit_cpu'
      Process.const_set :RLIMIT_RSS, 'rlimit_rss'
    end

    flexmock(Process).should_receive(:setrlimit).
                      with(Process::RLIMIT_CPU, 1, 5).once.and_return(nil)
    flexmock(Process).should_receive(:setrlimit).
                      with(Process::RLIMIT_RSS, 64 * 1024 * 1024).once.
                      and_return(nil)

    Zerg::Support::Process::Helpers.set_rlimits :rlimit_cpu => [1, 5],
                                                :rlimit_rss => 64 * 1024 * 1024
  end

  def test_process_group_processing
    flexmock(Process).should_receive(:setpgid).with(0, 42).once.and_return(nil)
    flexmock(Process).should_receive(:setsid).with().once.and_return(nil)

    Zerg::Support::Process::Helpers.set_process_group :pgroup => 42
    Zerg::Support::Process::Helpers.set_process_group :pgroup => true
  end

  def test_process_group
    pid = Zerg::Support::Process.spawn 'ruby', ['-e', "sleep 0.5"],
                                       :pgroup => true
    pinfo = Zerg::Support::Process::process_info pid
    Process.waitpid pid

    assert pinfo[:state].index('s'), 'Failed to become session leader'
  end

  def test_rlimits
    t0 = Time.now
    pid = Zerg::Support::Process.spawn 'ruby',
        ['-e', "i = 0; t0 = Time.now; i += 1 while Time.now - t0 < 3.0"],
        :rlimit_cpu => 1
    Process.waitpid pid
    t1 = Time.now

    assert_operator t1 - t0, :>=, 0.95, 'Spawning failed'
    assert_operator t1 - t0, :<=, 2.0, 'Failed to apply rlimit_cpu'
  end
end
