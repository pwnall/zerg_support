require 'time'

# process management
module Zerg::Support::Process
  @@no_multiple_pids = false
  
  unless RUBY_PLATFORM =~ /win/ and RUBY_PLATFORM !~ /darwin/
    # Translates process info given by Sys::ProcTable into our own nicer format.
    def self.xlate_process_info(low_info)
      {
        :pid => low_info.pid,
        :parent_pid => low_info.ppid,
        :real_uid => low_info.ruid || -1,
        :real_gid => low_info.rgid || -1,
        :start_time => low_info.start,
        :nice => low_info.nice || 0,
        :priority => low_info.priority || 0,
        :syscall_priority => low_info.user_priority || 0,
        :resident_size => (low_info.id_rss || 0) * 1024,
        :code_size => (low_info.ix_rss || 0) * 1024,
        :virtual_size => (low_info.is_rss || 0) * 1024,
        :percent_cpu => low_info.pctcpu,
        :percent_ram => low_info.pctmem,
        :state => low_info.state,
        :command_line => low_info.cmdline
      }
    end
    
  else
    #:nodoc:
    def self.xlate_process_info(low_info)
      state = low_info.execution_state.to_s
      state << 's' if low_info.session_id == 0
      
      {
        :pid => low_info.pid,
        :parent_pid => low_info.ppid,
        :real_uid => -1,
        :real_gid => -1,
        :start_time => low_info.creation_date,
        :nice => 0,
        :priority => low_info.priority || 0,
        :syscall_priority => 0,
        :resident_size => low_info.working_set_size || 0,
        :code_size => 0,
        :virtual_size => low_info.virtual_size || 0,
        :percent_cpu => 0,
        :percent_ram => 0,
        :state => state,
        :command_line => low_info.cmdline || low_info.comm || ''
      }
    end    
  end
  
  # Collects information about a single process. Returns nil 
  def self.process_info(pid)
    pinfo = ps pid
    pinfo ? xlate_process_info(pinfo) : nil 
  end
  
  # Collects information about processes with the given pids.
  # Returns all processes if no list of pids is given.
  def self.processes(pids = nil)
    if @@no_multiple_pids and !pids.empty
      pids.map { |pid| process_info pid }
    else
      begin
        if pids
          ps_result = ps(pids)
        else
          ps_result = ps
        end
        ps_result.map { |pinfo| xlate_process_info pinfo }
      rescue TypeError
        # we're using the real sys-proctable, and its ps doesn't like multiple
        # arguments
        @@no_multiple_pids = true
        processes pids
      end
    end
  end
  
  # Collects information about processes with the given pids.
  # The information is returned indexed by the processes' pids.
  def self.processes_by_id(pids = nil)
    retval = {}
    self.processes(pids).each { |pinfo| retval[pinfo[:pid]] = pinfo } 
    return retval
  end
  
  # Returns information about the descendants of the process with the given pid.
  def self.process_tree(*root_pids)
    procs_by_ppid = {}
    proc_list = self.processes_by_id
    proc_list.each do |pid, pinfo|
      procs_by_ppid[pinfo[:parent_pid]] ||= []
      procs_by_ppid[pinfo[:parent_pid]] << pinfo
    end
    
    proc_queue = root_pids.map { |pid| proc_list[pid] }.select { |pinfo| pinfo }
    
    index = 0
    while index < proc_queue.length
      pid, index = proc_queue[index][:pid], index + 1
      next unless procs_by_ppid.has_key? pid
      proc_queue += procs_by_ppid[pid]
    end
    return proc_queue
  end
  
  
  if RUBY_PLATFORM =~ /win/ and RUBY_PLATFORM !~ /darwin/
    #:nodoc: Wrapper around Process.kill that works on all platforms.
    def self.kill_primitive(pid, force = false)
      Process.kill(force ? 9 : 4, pid)
    end
  else
    #:nodoc: Wrapper around Process.kill that works on all platforms.
    def self.kill_primitive(pid, force = false)
      Process.kill(force ? 'KILL' : 'TERM', pid)      
    end
  end
  
  # Kills the process with the given pid.
  def self.kill(pid)
    begin
      self.kill_primitive pid, false
      Thread.new(pid) do |victim_pid|
        Kernel.sleep 0.2
        self.kill_primitive pid, true
      end
    rescue
      # we probably don't have the right to kill the process
      print "#{$!.class.name}: #{$!}\n"
    end    
  end
  
  # Kills all the processes descending from the process with the given pid.
  def self.kill_tree(root_pid)
    self.process_tree(root_pid).each do |pinfo|
      self.kill pinfo[:pid]
    end
  end
end


## Backend for process information listing

begin
  raise 'Use ps' unless RUBY_PLATFORM =~ /win/ and RUBY_PLATFORM !~ /darwin/
  
  require 'time'
  require 'sys/proctable'
  
  module Zerg::Support::Process
    def self.ps(pid = nil)
      Sys::ProcTable.ps pid
    end
  end 
rescue Exception
  # Emulate the sys-proctable gem using the ps command.
  # This will be slower than having native syscalls, but at least it doesn't
  # crash ruby. (yes, sys-proctable 0.7.6, I mean you!)
    
  #:nodoc: all
  module Zerg::Support::ProcTable
    class ProcInfo
      def initialize(pid, ppid, ruid, rgid, uid, gid, start, nice, rss, rssize,
                     text_size, vsz, user_time, total_time, pctcpu, pctmem,
                     priority, user_priority, state, cmdline)
        @pid, @ppid, @ruid, @rgid, @uid, @gid, @nice, @priority,
             @user_priority = *([pid, ppid, ruid, rgid, uid, gid, nice,
                                 priority, user_priority].map { |s| s.to_i })
        @start = Time.parse start
        @ix_rss, @id_rss, @is_rss = text_size.to_f, rssize.to_f, vsz.to_f
        @pctcpu, @pctmem = *([pctcpu, pctmem].map { |s| s.to_f })
        @cmdline = cmdline
        
        # TODO(victor): translate UNIX strings into something else
        @state = state
      end
      attr_reader :pid, :ppid, :ruid, :rgid, :uid, :gid, :nice, :priority,
                  :user_priority, :start, :ix_rss, :id_rss, :is_rss, :pctcpu,
                  :pctmem, :state, :cmdline
    end

    @@ps_root_cmdline = 'ps -o pid,ppid,ruid,rgid,uid,gid' +
                        ',lstart="STARTED_________________________________"' +
                        ',nice,rss,rssize,tsiz,vsz,utime,cputime,pcpu="PCPU_"' +
                        ',pmem="PMEM_",pri,usrpri,stat,command'
                        
    @@ps_all_cmdline = @@ps_root_cmdline + ' -A'
    @@ps_some_cmdline = @@ps_root_cmdline + ' -p '

    def self.ps(pid = nil)
      pids = pid ? (pid.kind_of?(Enumerable) ? pid : [pid]) : []
      retval = []
      ps_cmdline = pids.empty? ? @@ps_all_cmdline :
                                 @@ps_some_cmdline + pids.join(',')
      ps_output = Kernel.` ps_cmdline
      header_splits = nil
      ps_output.each_line do |pline|
        if header_splits
          # result line, break it up
          retval << ProcInfo.new(*(header_splits.map { |hs| pline[hs].strip }))
        else
          # first line, compute headers
          lengths = pline.split(/\S\s/).map { |h| h.length + 2 }
          header_splits, sum = [], 0
          lengths.each_index do |i|
            header_splits[i] = Range.new sum, sum += lengths[i], true
          end
          header_splits[-1] = Range.new header_splits[-1].begin, -1, false          
        end
      end
      return pids.length == 1 ? retval.first : retval
    end
  end
  
  module Zerg::Support::Process
    def self.ps(pid = nil)
      Zerg::Support::ProcTable.ps pid
    end
  end   
end
