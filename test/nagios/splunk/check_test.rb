require File.join(File.dirname(__FILE__), '../../test_helper')

describe Nagios::Splunk::Check do

  before do
    @client = MiniTest::Mock.new
    @response = MiniTest::Mock.new
    @response1 = MiniTest::Mock.new
    @check = Nagios::Splunk::Check.new(@client)
    @licenses_xml = File.read(File.join(MiniTest.fixtures_path, "licenses.xml"))
    @pools_xml = File.read(File.join(MiniTest.fixtures_path, "pools.xml"))
    @licenses = {
      "AAA" => {"quota" => "100", "status" => "VALID", "type" => "enterprise"},
      "BBB" => {"quota" => "200", "status" => "EXPIRED", "type" => "enterprise"},
      "CCC" => {"quota" => "300", "status" => "VALID", "type" => "forwarder"}
    }
    @pools = {
      "AAA" => {"used_bytes" => "10"},
      "BBB" => {"used_bytes" => "20"}
    }
  end

  describe "when fetch data" do

    describe "and response code is not 200 OK" do

      before do
        @response.expect(:code, "404")
        @response.expect(:body, "")
      end

      it "should have empty license list" do
        @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])
        @check.licenses.must_equal Hash.new
      end

      it "should have empty pools list" do
        @client.expect(:get, @response, [Nagios::Splunk::POOL_LIST_URL])
        @check.pools.must_equal Hash.new
      end

    end

    describe "and body is empty" do

      before do
        @response.expect(:code, "200")
        @response.expect(:body, "<xml />")
      end

      it "should have empty license list" do
        @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])
        @check.licenses.must_equal Hash.new
      end

      it "should have empty pools list" do
        @client.expect(:get, @response, [Nagios::Splunk::POOL_LIST_URL])
        @check.pools.must_equal Hash.new
      end

    end

    it "should be able to fetch licenses" do
      @response.expect(:code, "200")
      @response.expect(:body, @licenses_xml)
      @client.expect(:get, @response, [Nagios::Splunk::LICENSE_LIST_URL])
      @check.licenses.must_equal @licenses
    end

    it "should be able to fetch pools" do
      @response.expect(:code, "200")
      @response.expect(:body, @pools_xml)
      @client.expect(:get, @response, [Nagios::Splunk::POOL_LIST_URL])
      @check.pools.must_equal @pools
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
      message = "License CRITICAL: 30% of license capacity is used | quota: 100 B; used: 30 B"
      @check.license_usage(10, 20).must_equal [2, message]
    end

    it "should return WARN alert" do
      message = "License WARN: 30% of license capacity is used | quota: 100 B; used: 30 B"
      @check.license_usage(20, 40).must_equal [1, message]
    end

    it "should return OK" do
      message = "License OK: 30% of license capacity is used | quota: 100 B; used: 30 B"
      @check.license_usage(40, 50).must_equal [0, message]
    end
  end

end
