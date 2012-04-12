module Nagios

  STATUS = { 1 => "WARN", 2 => "CRITICAL", 0 => "OK" }

  module Splunk

    LOGIN_URL = "/services/auth/login"
    POOL_LIST_URL = "/services/licenser/pools"
    LICENSE_LIST_URL = "/services/licenser/licenses"

    autoload :Check, "splunk/check"
    autoload :RestClient, "splunk/rest_client"
    autoload :CLI, "splunk/cli"

  end
end
