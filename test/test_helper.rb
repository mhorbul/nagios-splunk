$:.push File.join(File.dirname(__FILE__), "../lib/nagios")

require 'rubygems'
require "bundler/setup"
require 'splunk'
require 'minitest/autorun'

module MiniTest
  def self.fixtures_path
    File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))
  end
end
