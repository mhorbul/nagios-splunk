require File.join(File.dirname(__FILE__), '../../test_helper')

describe Nagios::Splunk::Check do

  before do
    @client = MiniTest::Mock.new
    @response = MiniTest::Mock.new
    @response1 = MiniTest::Mock.new
    @check = Nagios::Splunk::Check.new(@client)
    @licenses_xml = File.read(File.join(MiniTest.fixtures_path, "licenses.xml"))
    @pools_xml = File.read(File.join(MiniTest.fixtures_path, "pools.xml"))
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
      @response.expect(:code, "200")
      @response.expect(:body, @licenses_xml)
      @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])

      @response1.expect(:code, "200")
      @response1.expect(:body, @pools_xml)
      @client.expect(:get, @response1, [Nagios::Splunk::POOL_LIST_URL])
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
      @response.expect(:body, @licenses_xml)
      @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])

      @response1.expect(:code, "200")
      @response1.expect(:body, @pools_xml)
      @client.expect(:get, @response1, [Nagios::Splunk::POOL_LIST_URL])
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
