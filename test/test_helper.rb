$:.push File.join(File.dirname(__FILE__), "../lib")

require 'rubygems'
require "bundler/setup"
require 'nagios/splunk'
require 'minitest/autorun'

module MiniTest
  def self.fixtures_path
    File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))
  end
end
