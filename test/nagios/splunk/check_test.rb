require File.join(File.dirname(__FILE__), '../../test_helper')

describe Nagios::Splunk::Check do

  before do
    @client = MiniTest::Mock.new
    @response = MiniTest::Mock.new
    @response1 = MiniTest::Mock.new
    @licenses_xml = File.read(File.join(MiniTest.fixtures_path, "licenses.xml"))
    @pools_xml = File.read(File.join(MiniTest.fixtures_path, "pools.xml"))
    @localslave_xml = File.read(File.join(MiniTest.fixtures_path, "localslave.xml"))

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


end
