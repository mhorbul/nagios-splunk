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
      "AAA" => {"quota" => "54760833024", "status" => "VALID", "type" => "enterprise"},
      "BBB" => {"quota" => "200", "status" => "EXPIRED", "type" => "enterprise"},
      "CCC" => {"quota" => "300", "status" => "VALID", "type" => "forwarder"}
    }
    @pools ={
      "auto_generated_pool_enterprise"=> {
        "requiredFields"=>"", "owner"=>"nobody", "slaves"=>"*",
        "optionalFields"=>"append_slavesdescriptionquotaslaves",
        "can_list"=>"1", "39C4C086-4F05-4349-9364-DA89E89DAAC2"=>"30949055311",
        "removable"=>"0", "quota"=>"MAX", "modifiable"=>"0",
        "eai:acl"=>"system110nobodyadminadmin0system",
        "description"=>"auto_generated_pool_enterprise",
        "stack_id"=>"enterprise", "slaves_usage_bytes"=>"30949055311",
        "eai:attributes"=>"append_slavesdescriptionquotaslaves",
        "can_write"=>"1",
        "sharing"=>"system", "write"=>"admin", "perms"=>"adminadmin",
        "app"=>"system", "wildcardFields"=>"", "used_bytes"=>"30949055311", "read"=>"admin"
      }
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

end
