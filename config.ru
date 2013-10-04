require "rubygems"
require "sinatra"

require File.expand_path '../chef_config_server.rb', __FILE__

run ChefConfigServer
