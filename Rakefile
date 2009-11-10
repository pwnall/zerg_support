require 'rubygems'
gem 'echoe'
require 'echoe'

Echoe.new('zerg_support') do |p|
  p.project = 'zerglings'  # rubyforge project
  
  p.author = 'Victor Costan'
  p.email = 'victor@zergling.net'
  p.summary = 'Support libraries used by Zergling.Net deployment code.'
  p.url = 'http://github.com/costan/zerg_support'
  
  p.need_tar_gz = !Gem.win_platform?
  p.need_zip = !Gem.win_platform?
  p.rdoc_pattern = /^(lib|bin|tasks|ext)|^BUILD|^README|^CHANGELOG|^TODO|^LICENSE|^COPYING$/
  
  p.development_dependencies = ['echoe >=3.0.2',
                                'event_machine >=0.12.2',
                                'flexmock >=0.8.3',
                               ]
end

if $0 == __FILE__
  Rake.application = Rake::Application.new
  Rake.application.run
end
