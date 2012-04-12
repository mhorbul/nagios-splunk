require 'mixlib/cli'

module Nagios
  module Splunk

    class CLI
      include Mixlib::CLI

      option(:server_url,
             :short => "-s URL",
             :long  => "--server URL",
             :required => true,
             :description => "Splunk server url",
             :on => :head)

      option(:warn,
             :short => "-w WARN",
             :long  => "--warn WARN",
             :default => '80',
             :description => "Warn % of license capacity usage (default: 80)")

      option(:crit,
             :short => "-c CRIT",
             :long  => "--crit CRIT",
             :default => '90',
             :description => "Critical % of license capacity usage (default: 90)")

      def run(argv = ARGV)
        parse_options(argv)

        client = RestClient.new(config[:server_url])
        splunk = Check.new(client)

        status, message = splunk.license_usage(config[:warn], config[:crit])

        puts message
        status
      end
    end

  end
end
