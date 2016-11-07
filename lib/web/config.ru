require "rubygems"
require "bundler/setup"

Bundler.require(:default)

require "sinatra/reloader" if development?
require File.expand_path "../burnie_web.rb", __FILE__

run BurnieWeb
