require "rubygems"
require "sinatra/base"
require "open3"

class BurnieWeb < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get "/" do
    erb :index
  end

  %w(schedule standings gamethread).each do |command|
    get "/#{command}" do
      @output, @error, @status = Open3.capture3("./burnie", command)
      erb :command, locals: { command: command, output: @output, status: @status, error: @error }
    end
  end
end
