module Nagios
  module Splunk
    class Exception < ::Exception
    end

    class NoLicensesFound < Exception
    end

    class NoPoolsFound < Exception
    end
  end
end
