require 'nokogiri'

module Nagios

  module Splunk

    # Nagios::Splunk::Check implements different types of checks of
    class Check

      attr_reader :rest_client

      # @param [String] server_url full server url with username and password (RFC 3986)
      # example: https://user:pass@localhost:8089/
      def initialize(client)
        @rest_client = client
      end

      # license usage check
      # @param [Integer] warn license usage threshhold
      # @param [Integer] crit license usage threshhold
      # @return [Array<Integer, String>] exit code and message
      def license_usage(warn, crit)
        quota = licenses.
          select {|k,v| v["type"] == "enterprise" && v["status"] == "VALID" }.
          reduce(0) { |r,l| r+=l[1]["quota"].to_i }
        used_quota = pools.reduce(0) {|r,p| r+=p[1]["used_bytes"].to_i }
        case true
        when used_quota > quota * crit.to_i / 100:
            code = 2
        when used_quota > quota * warn.to_i / 100:
            code = 1
        else
          code = 0
        end
        message = "License #{STATUS[code]}: #{used_quota * 100 / quota}% of license capacity is used"
        message << " | quota: #{quota} B; used: #{used_quota} B"
        return [code, message]
      end

      # list of avialable licenses
      # @return [Array<Hash>]
      def licenses
        response = rest_client.get(LICENSE_LIST_URL)
        response.code == "200" ? parse_data(response.body) : {}
      end

      # list of available pools
      # @return [Array<Hash>]
      def pools
        response = rest_client.get(POOL_LIST_URL)
        response.code == "200" ? parse_data(response.body) : {}
      end

      private

      def parse_data(data)
        doc = Nokogiri::Slop(data)
        doc.remove_namespaces!
        doc.search("entry").reduce(Hash.new) do |r,e|
          name = e.title.content
          next r if name =~ /^F+D{0,1}$/
          r[name] ||= Hash.new
          e.search("dict/key").each do |k|
            r[name][k.attribute("name").value] = k.text
          end
          r
        end
      end

    end

  end
end
