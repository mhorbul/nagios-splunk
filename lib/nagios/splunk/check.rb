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

      def localslave(warn, crit)
        response = rest_client.get(LICENSE_LOCALSLAVE_URL)
        result = response.code == "200" ? parse_data(response.body) : {}
        last_success_ago = Time.now - result['license']['last_master_contact_success_time'].to_i
        code = case true
               when last_success_ago.to_i > crit.to_i then 2
               when last_success_ago.to_i > warn.to_i then 1
               else 0
               end
        message = "License slave #{result['license']['slave_label']} #{STATUS[code]}"
        message << " | last_master_contact_attempt_time: #{result['license']['last_master_contact_attempt_time']}; last_master_contact_success_time: #{result['license']['last_master_contact_success_time']}"
        return [code, message]
      end


      # pool usage check
      # @param [String] name of the pool
      # @param [Integer] warn license usage threshhold
      # @param [Integer] crit license usage threshhold
      # @param [String] stack_id which pool is assigned to
      # @return [Array<Integer, String>] exit code and message
      def pool_usage(name, warn, crit)
        quota = pool_quota(name)
        used_quota = find_pool_by_name(name)["used_bytes"].to_i

        code = check_threshold(used_quota, quota, warn, crit)

        message = "License pool '#{name}' #{STATUS[code]}: #{used_quota * 100 / quota}% of license pool capacity is used"
        message << " | quota: #{quota} B; used: #{used_quota} B"
        return [code, message]
      end

      # license usage check
      # @param [Integer] warn license usage threshhold
      # @param [Integer] crit license usage threshhold
      # @param [String] stack_id
      # @return [Array<Integer, String>] exit code and message
      def license_usage(warn, crit, stack_id = "enterprise")
        quota = license_quota(stack_id)
        used_quota = pools_in_stack_usage(stack_id)

        code = check_threshold(used_quota, quota, warn, crit)

        message = "License #{STATUS[code]}: #{used_quota * 100 / quota}% of license capacity is used"
        message << " | quota: #{quota} B; used: #{used_quota} B"
        return [code, message]
      end

      def cluster_bundle_status
        splunk = Splunk.new(rest_client)
        info = splunk.cluster_master_info
        errors = info.xpath("//s:key[@name='bundle_validation_errors_on_master']//s:item").map { |n| n.text.chomp }
        code = (errors.empty? ? 0 : 1)
        return [code, "Splunk cluster bundle status is #{STATUS[code]} | #{errors.join("\n")}"]
      end

      def cluster_replication_factor
        splunk = Splunk.new(rest_client)
        info = splunk.cluster_master_generation
        code = info.xpath("//s:key[@name='replication_factor_met']").text.to_i
        return [code == 1 ? 0 : 1, "Splunk cluster replication factor is #{code == 1 ? "met" : "not met"}"]
      end

      def cluster_search_factor
        splunk = Splunk.new(rest_client)
        info = splunk.cluster_master_generation
        code = info.xpath("//s:key[@name='search_factor_met']").text.to_i
        return [code == 1 ? 0 : 1, "Splunk cluster search factor is #{code == 1 ? "met" : "not met"}"]
      end

      private

      # Compare usage and quota with threshold
      # @param [Integer] usage
      # @param [Integer] quota
      # @param [Integer] warn
      # @param [Integer] crit
      # @return [Integer] exit code
      def check_threshold(usage, quota, warn, crit)
        case true
        when usage > quota * crit.to_i / 100
          return 2
        when usage > quota * warn.to_i / 100
          return 1
        else
          return 0
        end
      end

      # Find out pool quota
      # @param [String] name of the pool
      # @return [Integer] quota number of bytes
      def pool_quota(name)
        pool = find_pool_by_name(name)
        # get license quota if it is not limited
        pool["quota"] == "MAX" ? license_quota(pool["stack_id"]) : pool["quota"].to_i
      end

      # Find out license quota
      # @param [String] stack_id licesne stack
      # @return [Integer] license stack quota in bytes
      def license_quota(stack_id)
        find_licenses(stack_id).reduce(0) { |r,l| r+=l[1]["quota"].to_i }
      end

      # Find out pool(s) license usage
      # @param [String] stack_id which pools are assigned to
      # @retunr [Integer] number of bytes used by pool(s)
      def pools_in_stack_usage(stack_id)
        pools = find_pools(stack_id)
        pools.reduce(0) {|r,p| r+=p[1]["used_bytes"].to_i }
      end

      # list of avialable licenses
      # @param [String] stack_id
      # @return [Array<Hash>]
      def find_licenses(stack_id)
        @licenses ||= {}
        @licenses[stack_id] ||=
          begin
            response = rest_client.get(LICENSE_LIST_URL)
            result = response.code == "200" ? parse_data(response.body) : {}
            # find all VALID licenses by stack_id
            result.reject! {|k,v| v["stack_id"] != stack_id || v["status"] != "VALID" }
            raise NoLicensesFound.new("No licenses are found in stack '#{stack_id}'") if result.empty?
            result
          end
      end

      # list of available pools
      # @param [String] stack_id
      # @return [Array<Hash>]
      def find_pools(stack_id = nil)
        @license_pools ||= {}
        @license_pools[stack_id || :all] ||=
          begin
            response = rest_client.get(POOL_LIST_URL)
            result = response.code == "200" ? parse_data(response.body) : {}
            # find all license pools by stack_id
            result.reject! {|k,v| v["stack_id"] != stack_id } unless stack_id.nil?
            raise NoPoolsFound.new("No pools are found in stack '#{stack_id}'") if result.empty?
            result
          end
      end

      # Find pool by name
      # param [String] name of the pool
      # @return [Hash] pool
      def find_pool_by_name(name)
        pools = find_pools
        result = pools.find { |k,v| k == name } # => ["pool-name", { "param1" => "value1" }]
        raise NoPoolsFound.new("No pool named '#{name}' is found") if result.nil?
        # return hash of parameters for the pool
        result[1]
      end

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
