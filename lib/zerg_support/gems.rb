# methods used in gem installation hooks
module Zerg::Support::Gems
  # called by ensure_on_path for Windows systems
  def self.ensure_on_windows_path(bin_file)
    bat_file = File.expand_path(File.join(ENV["WINDIR"],
                                File.basename(bin_file) + ".bat"))
    begin
      File.open(bat_file, 'w') do |f|
        f.write <<END_BATCH
@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
@"ruby.exe" "#{File.expand_path(bin_file)}" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
@"ruby.exe" "#{File.expand_path(bin_file)}" %*
END_BATCH
      end
    #rescue
      # if anything goes wrong we probably don't have permissions (hi Vista?)
    end    
  end
  
  # called by ensure_on_path for UNIX systems
  def self.ensure_on_unix_path(bin_file)
    path = "/usr/bin/#{File.basename bin_file}"
    begin
      # using a link so the gem can be updated and the link still works
      FileUtils.ln_s(bin_file, path, :force)
    rescue
      # if anything goes wrong we probably don't have permissions
      # oh well at least we tried
    end
  end
  
  # ensures that bin_file can be invoked from a shell
  def self.ensure_on_path(bin_script)
    caller_trace = Kernel.caller.first
    caller_match = /^(.*)\:\d+\:in /.match(caller_trace) ||
                   /^(.*)\:\d+$/.match(caller_trace)
    bin_file = File.expand_path caller_match[1] + '/../../../bin/' + bin_script
    # this is a cheat to get the binary in the right place on stubborn Debians
    if RUBY_PLATFORM =~ /win/ and RUBY_PLATFORM !~ /darwin/
      ensure_on_windows_path bin_file
    else
      ensure_on_unix_path bin_file
    end
  end
  
  # tricks rubygems into believeing that the extension compiled and worked out
  def self.emulate_extension_install(extension_name)
    File.open('Makefile', 'w') { |f| f.write "all:\n\ninstall:\n\n" }
    File.open('make', 'w') do |f|
      f.write '#!/bin/sh'
      f.chmod f.stat.mode | 0111
    end
    File.open(extension_name + '.so', 'w') {}
    File.open(extension_name + '.dll', 'w') {}
    File.open('nmake.bat', 'w') { |f| }
  end
end
