#:nodoc:
module Zerg::Support::Process
  # perhaps this should be merged in process
end

if RUBY_PLATFORM =~ /win/ and RUBY_PLATFORM !~ /darwin/
  require 'win32/process'

  #:nodoc: all
  module Zerg::Support::Process
    def self.spawn(binary, args = [], options = {})
      # command line processing
      command_line = '"' + binary + '" "' +
          args.map { |a| a.gsub '"', '""' }.join('" "') + '"'
      
      # environment processing
      environment_string = nil
      if options[:env]
        if options[:unsetenv_others]
          environment = options[:env]
        else
          environment = Hash.new.merge(ENV).merge(options[:env])
        end
        environment_string = environment.keys.sort.
            map { |k| "#{k}=#{environment[k]}" }.join "\0"
        environment_string << "\0"
      end
      
      # redirection processing
      startup_info = {}
      files = {}
      stream_files = {}
      deferred_opens = []
      [[STDIN, :stdin], [STDOUT, :stdout], [STDERR, :stderr]].each do |pair|
        next unless options[pair.first]
        if options[pair.first].kind_of? String
          filename = options[pair.first]
          files[filename] ||= File.open(filename,
                                        (pair.last == :stdin) ? 'r' : 'w+')
          startup_info[pair.last] = files[filename]
          stream_files[pair.first] = files[filename]
        else
          deferred_opens << Kernel.proc do
            io = stream_files[options[pair.first]] || pair.first
            startup_info[pair.last] = stream_files[pair.first] = io
          end
        end
      end
      deferred_opens.each { |d| d.call }
      
      # process leader
      creation_flags = 0
      if options[:pgroup]
        creation_flags |= Process::DETACHED_PROCESS
        if options[:pgroup].kind_of? Numeric and options[:pgroup] > 0
          # TODO: what now?
        else
          creation_flags |= Process::CREATE_NEW_PROCESS_GROUP
        end
      end
      
      info = Process.create :command_line => command_line,
                            :cwd => options[:chdir] || Dir.pwd,
                            :environment => environment_string,
                            :creation_flags => creation_flags,
                            :startup_info => startup_info                            
      files.each { |name, io| io.close }
      
      return info[:process_id]
    end
  end
  
else

  #:nodoc:
  module Zerg::Support::Process
    # Spawns a new process and returns its pid immediately.
    # Like Kernel.spawn in ruby1.9, except that the environment is passed
    # as an option with the key :env
    def self.spawn(binary, args = [], options = {})
      if Kernel.respond_to? :spawn
        # ruby1.9+: spawn!
        options = options.dup
        env = options.delete(:env)
        Kernel.spawn(*([env, binary] + args + [options]))
      else
        # below 1.9: emulate
        
        # chdir option
        Dir.chdir options[:chdir] if options[:chdir]
        
        child_pid = fork do
          Helpers.do_redirects options
          Helpers.close_fds options          
          Helpers.set_process_group options          
          Helpers.set_environment options
          Helpers.set_rlimits options
          
          Kernel.exec(*([binary] + args))
        end
      end
      
      return child_pid
    end
  end  
end

# Helpers for spawning processes.
module Zerg::Support::Process::Helpers
  # Closes all open file descriptors except for stdin/stdout/stderr
  def self.close_fds(options)
    return if options[:close_others] == false
    
    ObjectSpace.each_object(IO) do |io|
      next if [STDIN, STDOUT, STDERR].include? io
      
      begin
        io.close unless io.closed?
      rescue Exception
      end
    end
  end
  
  # Sets process limits (rlimits) according to the given options. The options
  # follow the convention of Kernel.spawn in ruby1.9
  def self.set_rlimits(options)
    # rlimit options
    options.each do |k, v|
      next unless k.kind_of? Symbol and k.to_s[0, 7] == 'rlimit_'
      rconst = Process.const_get k.to_s.upcase.to_sym
      if v.kind_of? Enumerable
        Process.setrlimit rconst, v.first, v.last
      else
        Process.setrlimit rconst, v
      end              
    end    
  end
  
  # Sets the process' group according to the given options. The options
  # follow the convention of Kernel.spawn in ruby1.9
  def self.set_process_group(options)
    return unless options[:pgroup]
    
    if options[:pgroup].kind_of? Numeric and options[:pgroup] > 0
      Process.setpgid 0, options[:pgroup]
    else
      Process.setsid
    end
  end
  
  # Sets the process' environment according to the given options. The options
  # follow the convention of Kernel.spawn in ruby1.9
  def self.set_environment(options)
    return unless options[:env]
    
    ENV.clear if options[:unsetenv_others]
    options[:env].each do |key, value|
      ENV[key] = value
    end
  end
  
  # Performs IO redirections according to the given options. The options
  # follow the convention of Kernel.spawn in ruby1.9
  def self.do_redirects(options)
    redirected_files = {}
    file_redirects = []
    fd_redirects = []
    options.each do |key, value|
      next unless key.kind_of? IO
      if value.kind_of? String
        if redirected_files[value]
          fd_redirects << [key, redirected_files[value]]
        else
          file_redirects << [key, value]
          redirected_files[value] = key
        end
      else
        fd_redirects << [key, value]
      end
    end
    (file_redirects + fd_redirects).each do |r|
      r.first.reopen r.last
    end
  end
end
