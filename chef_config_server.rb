#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'json'
require 'sinatra/base'
require 'sinatra/config_file'
require 'chef'

class ChefConfigServer < Sinatra::Base
  register Sinatra::ConfigFile

  config_file File.expand_path '../config/config.yml', __FILE__

  def initialize()

    super
    setup_chef

    @encrypted_bags = settings.encrypted_databags
    @node_info = Chef::Node.load(Chef::Config[:node_name])
    @bags = config_retriever(@node_info.chef_environment.to_sym, @encrypted_bags)
  end

  def setup_chef()
    system = Ohai::System.new

    %w(os hostname).each do |plugin|
      system.require_plugin(plugin)
    end

    Chef::Config[:node_name] = system['hostname']
    Chef::Config[:chef_server_url] = settings.chef_config['chef_server_url']
    file_path = File.expand_path "../#{settings.chef_config['data_bag_encryption_file']}", __FILE__
    Chef::Config[:encrypted_data_bag_secret] = file_path
  end

  def config_retriever(environment, encrypted_bags)
    bags = Chef::DataBag.list
    settings = {}
    bags.each_key do |cur_bag|
      if (encrypted_bags.include?(cur_bag.to_sym) == true) then
        target_bag = Chef::EncryptedDataBagItem.load(cur_bag, environment)
        settings[cur_bag] = target_bag.to_hash.keys.inject({}) {|hash, key| hash[key] = target_bag[key] unless ['id'].include?(key); hash}
      else
        target_bag = Chef::DataBagItem.load(cur_bag, environment)
        settings[cur_bag] = target_bag.to_hash.tap { |hs| ['id', 'chef_type', 'data_bag'].each { |del_key| hs.delete(del_key)}}
      end
    end
    settings
  end

  before do
    content_type 'application/json'
  end

  get '/config/' do
    @bags.to_json
  end

  get '/config/:topic/' do |topic|
    @bags[topic].to_json
  end

  get '/config/:topic/:subject' do |topic, subject|
    bag = @bags[topic]
    (bag && bag[subject]).to_json
  end

  # start the server if ruby file executed directly
  run! if app_file == $0

end
