$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "nagios-splunk"
  s.version     = "1.0.0"
  s.authors     = 'Max Horbul'
  s.email       = ["max@gorbul.net"]
  s.homepage    = "https://github.com/mhorbul/nagios-splunk"
  s.rubyforge_project = 'nagios-splunk'
  s.summary     = "Nagios Splunk plugin"
  s.description = "Splunk monitoring in Nagios"

  s.files         = Dir['{bin/*,lib/**/*,test/*}'] +
    %w{README Rakefile nagios-splunk.gemspec}

  s.bindir          = 'bin'
  s.executables     << 'check_splunk'
  s.require_path    = 'lib'

  s.add_dependency 'nokogiri'
  s.add_dependency 'mixlib-cli'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'

  s.has_rdoc = false
end
