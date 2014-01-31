require 'mixlib/cli'

module Nagios
  module Splunk

    class CLI
      include Mixlib::CLI

      option(:server_url,
             :short => "-u URL",
             :long  => "--server-url URL",
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

      option(:pool,
             :short => "-p POOL",
             :long  => "--pool-name POOL",
             :description => "Pool name wich usage is being checked.")

      option(:localslave,
             :short => "-L",
             :long  => "--localslave-check",
             :description => "Run localslave check.")

      option(:stack_id,
             :short => "-s STACK_ID",
             :long  => "--stack-id STACK_ID",
             :default => 'enterprise',
             :description => "License Stack ID.")

      def run(argv = ARGV)
        parse_options(argv)

        client = RestClient.new(config[:server_url])
        splunk = Check.new(client)

        begin
          if config[:localslave]
            status, message = splunk.localslave(config[:warn], config[:crit])
          elsif config[:pool]
            status, message = splunk.pool_usage(config[:pool], config[:warn], config[:crit])
          else
            status, message = splunk.license_usage(config[:warn], config[:crit], config[:stack_id])
          end
        rescue Nagios::Splunk::Exception => e
          message = e.message
          status = 3
        end

        puts message
        status
      end
    end

  end
end
