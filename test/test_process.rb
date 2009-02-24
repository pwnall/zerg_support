require 'English'
require 'test/unit'

require 'zerg_support'

class TestProcess < Test::Unit::TestCase
  def teardown
    @pid_files.each { |f| File.delete f rescue nil } if @pid_files
    super
  end
  
  def test_process_info
    info = Zerg::Support::Process.process_info($PID)
    assert info, 'Failed to find current process'
    
    $ARGV.each do |arg|
      assert info[:command_line].index(arg),
             "Command line for current process does not contain argument #{arg}"
    end
  end
  
  def test_process_list_contains_current_process
    list = Zerg::Support::Process.processes_by_id
    
    assert list[$PID], 'Process list does not contain current process'
  end

  # spawn 2^(exp+1)-1 children, and their command lines will contain "cookie"
  def spawn_sleepers(exp, cookie)
    Thread.new { system "ruby test/fork_tree.rb -- #{exp} 100 #{cookie}" }
    on_windows = RUBY_PLATFORM =~ /win/ && RUBY_PLATFORM !~ /darwin/
    sleep on_windows ? 0.5 : 0.1
    pid_file = "#{cookie}.pid"
    @pid_files ||= []
    @pid_files << pid_file
    pid = File.read(pid_file).to_i
    sleep on_windows ? 0.4 : 0.5
    return pid
  end
  
  def now_cookie
    "zerg_test_#{Time.now.to_f}s"
  end
  
  def test_process_tree
    cookie = now_cookie
    root_pid = spawn_sleepers 3, cookie
    
    tree_processes = Zerg::Support::Process.process_tree root_pid    
    assert_equal 15, tree_processes.length, 'Missed some processes'
    assert tree_processes.all? { |info| info[:command_line].index cookie },
           'Got the wrong processes'
           
    Zerg::Support::Process.kill_tree root_pid
  end
  
  def test_kill
    cookie = now_cookie
    victim_pid = spawn_sleepers 0, cookie
    
    Zerg::Support::Process.kill victim_pid
    sleep 0.5
    processes = Zerg::Support::Process.processes
    assert_equal nil, processes[victim_pid], 'Victim was not killed'
  end
  
  def test_kill_tree
    cookie = now_cookie
    root_pid = spawn_sleepers 3, cookie
     
    Zerg::Support::Process.kill_tree root_pid
    sleep 0.5
    processes = Zerg::Support::Process.processes
    escaped = processes.select { |info| info[:command_line].index cookie }
    
    assert_equal [], escaped, 'Some process(es) escaped'
  end
end