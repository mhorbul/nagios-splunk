require 'mixlib/cli'

module Nagios
  module Splunk

    class CLI
      include Mixlib::CLI

      option(:server_url,
             :short => "-s URL",
             :long  => "--server URL",
             :default => 'https://admin:changeme@localhost:8089/',
             :description => "Splunk server url")

      option(:warn,
             :short => "-w WARN",
             :long  => "--warn WARN",
             :default => '80',
             :description => "Warn % of license capacity usage")

      option(:crit,
             :short => "-c CRIT",
             :long  => "--crit CRIT",
             :default => '90',
             :description => "Critical % of license capacity usage")
    end

  end
end
