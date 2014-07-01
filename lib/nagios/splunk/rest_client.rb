require 'net/https'

module Nagios
  module Splunk

    # Rest client which communicates with Splunk via REST API
    class RestClient

      attr_reader :token

      # turn on/off debugging
      # @param [<True, False>]
      def self.debug(value = nil)
        @debug = value if value
        @debug
      end

      # parse server url string and set up intance variables
      # @param [String] server_url full server url with username and password (RFC 3986)
      # example: https://user:pass@localhost:8089/
      def initialize(server_url)
        uri = URI.parse(server_url)
        @host = uri.host
        @port = uri.port
        @username = uri.user
        @password = uri.password
        @use_ssl = (uri.scheme == "https")
      end

      # send HTTP request to the server
      # @param [String] url
      # @return [Net::HTTPRespose]
      def get(url)
        login unless token
        response = client.request(request(url, token))
      end

      private

      # build GET request and include Authorization
      # @param [String] url
      # @param [String] token authenticate token
      def request(url, token)
        headers = { "Authorization" => "Splunk #{token}" }
        Net::HTTP::Get.new(url, headers)
      end

      # build HTTP connection
      # @return [Net::HTTP]
      def client
        @client ||=
          begin do
            http = Net::HTTP.new(@host, @port)
            http.use_ssl = @use_ssl
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
            http.set_debug_output $stderr if debug
            http
          end
      end

      def debug
        self.class.debug
      end

      # receive authentication token
      def login
        request = Net::HTTP::Post.new(LOGIN_URL)
        request.set_form_data({"username" => @username, "password" => @password})
        response = client.request(request)
        if response.code == "200"
          doc = Nokogiri::XML.parse(response.body)
          elem = doc.search("//sessionKey").first
          @token = elem.text if elem
        end
      end

    end

  end
end
