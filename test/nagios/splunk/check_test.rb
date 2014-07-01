require File.join(File.dirname(__FILE__), '../../test_helper')

describe Nagios::Splunk::Check do

  before do
    @client = MiniTest::Mock.new
    @response = MiniTest::Mock.new
    @response1 = MiniTest::Mock.new
    @licenses_xml = File.read(File.join(MiniTest.fixtures_path, "licenses.xml"))
    @pools_xml = File.read(File.join(MiniTest.fixtures_path, "pools.xml"))
    @localslave_xml = File.read(File.join(MiniTest.fixtures_path, "localslave.xml"))

    @repl_search_factor_met_xml = File.read(File.join(MiniTest.fixtures_path, "repl-search-factor-met.xml"))
    @repl_search_factor_not_met_xml = File.read(File.join(MiniTest.fixtures_path, "repl-search-factor-not-met.xml"))

    @cluster_bundle_ok_xml = File.read(File.join(MiniTest.fixtures_path, "cluster-bundle-ok.xml"))
    @cluster_bundle_fail_xml = File.read(File.join(MiniTest.fixtures_path, "cluster-bundle-fail.xml"))

    @check = Nagios::Splunk::Check.new(@client)
  end

  describe "#localslave" do

    before do
      @response.expect(:code, "200")
      @response.expect(:body, @localslave_xml)
      @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LOCALSLAVE_URL])
    end

    it "should return CRITICAL alert" do
      time = 1391118534
      Time.stub(:now, Time.at(time + 180)) do
        message = "License slave slave01 CRITICAL | last_master_contact_attempt_time: #{time}; last_master_contact_success_time: #{time}"
        @check.localslave(60, 90).must_equal [2, message]
      end
    end

    it "should return WARNING alert" do
      time = 1391118534
      Time.stub(:now, Time.at(time + 70)) do
        message = "License slave slave01 WARN | last_master_contact_attempt_time: #{time}; last_master_contact_success_time: #{time}"
        @check.localslave(60, 90).must_equal [1, message]
      end
    end

    it "should return OK" do
      time = 1391118534
      Time.stub(:now, Time.at(time + 30)) do
        message = "License slave slave01 OK | last_master_contact_attempt_time: #{time}; last_master_contact_success_time: #{time}"
        @check.localslave(60, 90).must_equal [0, message]
      end
    end

  end

  describe "when check license usage" do

    before do
      @response.expect(:code, "200")
      @response.expect(:body, @licenses_xml)
      @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])

      @response1.expect(:code, "200")
      @response1.expect(:body, @pools_xml)
      @client.expect(:get, @response1, [Nagios::Splunk::POOL_LIST_URL])
    end

    it "should return CRITICAL alert" do
      message = "License CRITICAL: 56% of license capacity is used | quota: 54760833024 B; used: 30949055311 B"
      @check.license_usage(40, 50).must_equal [2, message]
    end

    it "should return WARN alert" do
      message = "License WARN: 56% of license capacity is used | quota: 54760833024 B; used: 30949055311 B"
      @check.license_usage(50, 60).must_equal [1, message]
    end

    it "should return OK" do
      message = "License OK: 56% of license capacity is used | quota: 54760833024 B; used: 30949055311 B"
      @check.license_usage(60, 70).must_equal [0, message]
    end
  end

  describe "when check pool usage with MAX quota" do

    before do
      @response1.expect(:code, "200")
      @response1.expect(:body, @pools_xml)
      @client.expect(:get, @response1, [Nagios::Splunk::POOL_LIST_URL])

      @response.expect(:code, "200")
      @response.expect(:body, @licenses_xml)
      @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])
    end

    it "should return CRITICAL alert" do
      message = "License pool 'auto_generated_pool_enterprise' CRITICAL: 56% of license pool capacity is used | quota: 54760833024 B; used: 30949055311 B"
      @check.pool_usage("auto_generated_pool_enterprise", 40, 50).must_equal [2, message]
    end

    it "should return WARN alert" do
      message = "License pool 'auto_generated_pool_enterprise' WARN: 56% of license pool capacity is used | quota: 54760833024 B; used: 30949055311 B"
      @check.pool_usage("auto_generated_pool_enterprise", 50, 60).must_equal [1, message]
    end

    it "should return OK" do
      message = "License pool 'auto_generated_pool_enterprise' OK: 56% of license pool capacity is used | quota: 54760833024 B; used: 30949055311 B"
      @check.pool_usage("auto_generated_pool_enterprise", 60, 70).must_equal [0, message]
    end
  end

  describe "when check pool usage with defined quota" do

    before do
      @response.expect(:code, "200")
      @response.expect(:body, @pools_xml)
      @client.expect(:get, @response, [Nagios::Splunk::POOL_LIST_URL])
    end

    it "should return CRITICAL alert" do
      message = "License pool 'limited-pool' CRITICAL: 50% of license pool capacity is used | quota: 61898110622 B; used: 30949055311 B"
      @check.pool_usage("limited-pool", 40, 49).must_equal [2, message]
    end

    it "should return WARN alert" do
      message = "License pool 'limited-pool' WARN: 50% of license pool capacity is used | quota: 61898110622 B; used: 30949055311 B"
      @check.pool_usage("limited-pool", 49, 60).must_equal [1, message]
    end

    it "should return OK" do
      message = "License pool 'limited-pool' OK: 50% of license pool capacity is used | quota: 61898110622 B; used: 30949055311 B"
      @check.pool_usage("limited-pool", 60, 70).must_equal [0, message]
    end

  end

  describe "replication/search factor check" do

    let(:splunk) { MiniTest::Mock.new }

    describe "replication / search factor met" do

      before do
        splunk.expect(:cluster_master_generation, Nokogiri::Slop(@repl_search_factor_met_xml))
      end

      it "should return OK" do
        message = "Splunk cluster replication factor is met"
        Nagios::Splunk::Splunk.stub(:new, splunk) do
          @check.cluster_replication_factor.must_equal [0, message]
        end
        splunk.verify
      end

      it "should return OK" do
        message = "Splunk cluster search factor is met"
        Nagios::Splunk::Splunk.stub(:new, splunk) do
          @check.cluster_search_factor.must_equal [0, message]
        end
        splunk.verify
      end

    end

    describe "replication / search factor is not met" do

      before do
        splunk.expect(:cluster_master_generation, Nokogiri::Slop(@repl_search_factor_not_met_xml))
      end

      it "should return OK" do
        message = "Splunk cluster replication factor is not met"
        Nagios::Splunk::Splunk.stub(:new, splunk) do
          @check.cluster_replication_factor.must_equal [1, message]
        end
        splunk.verify
      end

      it "should return OK" do
        message = "Splunk cluster search factor is not met"
        Nagios::Splunk::Splunk.stub(:new, splunk) do
          @check.cluster_search_factor.must_equal [1, message]
        end
        splunk.verify
      end

    end

  end

  describe "replication/search factor check" do

    let(:splunk) { MiniTest::Mock.new }

    describe "cluster bundle is valid" do

      before do
        splunk.expect(:cluster_master_info, Nokogiri::Slop(@cluster_bundle_ok_xml))
      end

      it "should return OK" do
        message = "Splunk cluster bundle status is OK | "
        Nagios::Splunk::Splunk.stub(:new, splunk) do
          @check.cluster_bundle_status.must_equal [0, message]
        end
        splunk.verify
      end

    end

    describe "cluster bundle is not valid" do

      before do
        splunk.expect(:cluster_master_info, Nokogiri::Slop(@cluster_bundle_fail_xml))
      end

      it "should return WARN alert" do
        message = "Splunk cluster bundle status is WARN |"
        error = ["No spec file for: /opt/splunk/etc/master-apps/SplunkforPaloAltoNetworks/default/nfi_pages.conf"]
        error << "No spec file for: /opt/splunk/etc/master-apps/maps/default/geoip.conf"
        error << "No spec file for: /opt/splunk/etc/master-apps/ossec/default/ossec_servers.conf"
        error << "\t\tInvalid key in stanza [rails] in /opt/splunk/etc/master-apps/rails/default/props.conf, line 13: TIME_PREFI  (value:  (for [\\d\\.]+ at\\s))"
        Nagios::Splunk::Splunk.stub(:new, splunk) do
          @check.cluster_bundle_status.must_equal [1, "#{message} #{error.join("\n")}"]
        end
        splunk.verify
      end

    end

  end

end
