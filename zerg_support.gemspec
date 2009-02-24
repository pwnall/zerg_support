# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{zerg_support}
  s.version = "0.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Victor Costan"]
  s.date = %q{2009-02-24}
  s.description = %q{Support libraries used by Zergling.Net deployment code.}
  s.email = %q{victor@zergling.net}
  s.extra_rdoc_files = ["CHANGELOG", "lib/zerg_support/event_machine/connection_mocks.rb", "lib/zerg_support/event_machine/frame_protocol.rb", "lib/zerg_support/event_machine/object_protocol.rb", "lib/zerg_support/gems.rb", "lib/zerg_support/open_ssh.rb", "lib/zerg_support/process.rb", "lib/zerg_support/spawn.rb", "lib/zerg_support.rb", "LICENSE", "README"]
  s.files = ["CHANGELOG", "lib/zerg_support/event_machine/connection_mocks.rb", "lib/zerg_support/event_machine/frame_protocol.rb", "lib/zerg_support/event_machine/object_protocol.rb", "lib/zerg_support/gems.rb", "lib/zerg_support/open_ssh.rb", "lib/zerg_support/process.rb", "lib/zerg_support/spawn.rb", "lib/zerg_support.rb", "LICENSE", "Manifest", "Rakefile", "README", "RUBYFORGE", "test/fork_tree.rb", "test/test_connection_mocks.rb", "test/test_frame_protocol.rb", "test/test_gems.rb", "test/test_object_protocol.rb", "test/test_open_ssh.rb", "test/test_process.rb", "test/test_spawn.rb", "zerg_support.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://www.zergling.net}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Zerg_support", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{zerg-support}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Support libraries used by Zergling.Net deployment code.}
  s.test_files = ["test/test_connection_mocks.rb", "test/test_frame_protocol.rb", "test/test_gems.rb", "test/test_object_protocol.rb", "test/test_open_ssh.rb", "test/test_process.rb", "test/test_spawn.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<echoe>, [">= 3.0.2"])
      s.add_development_dependency(%q<event_machine>, [">= 0.12.2"])
      s.add_development_dependency(%q<flexmock>, [">= 0.8.3"])
    else
      s.add_dependency(%q<echoe>, [">= 3.0.2"])
      s.add_dependency(%q<event_machine>, [">= 0.12.2"])
      s.add_dependency(%q<flexmock>, [">= 0.8.3"])
    end
  else
    s.add_dependency(%q<echoe>, [">= 3.0.2"])
    s.add_dependency(%q<event_machine>, [">= 0.12.2"])
    s.add_dependency(%q<flexmock>, [">= 0.8.3"])
  end
end
