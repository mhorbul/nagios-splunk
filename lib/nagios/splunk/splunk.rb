module Nagios
  module Splunk
    class Splunk

      attr_accessor :client

      def initialize(client)
        @client = client
      end

      def cluster_master_info
        response = @client.get("/services/cluster/master/info")
        Nokogiri::Slop(response.body) if response.code.to_i == 200
      end

      def cluster_master_generation
        response = @client.get("/services/cluster/master/generation")
        Nokogiri::Slop(response.body) if response.code.to_i == 200
      end

    end
  end
end
