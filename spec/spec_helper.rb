require 'rspec'
require 'webmock/rspec'

require './lib/burnie'

# Web Mocks
RSpec.configure do |config|
  config.before(:each) do
    stub_request(:get, /.*nba-schedule.herokuapp.com.*/).to_return(File.new("spec/fixtures/requests/schedule.request"))
    stub_request(:get, "http://www.nba.com/games/20141112/INDMIA/gameinfo.html").to_return(File.new("spec/fixtures/requests/gameinfo.final.request"))
  end
end
