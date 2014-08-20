require 'json'

class Configuration
  
  def initialize(filename = "config/settings.json")
    file = File.open(filename)
    @config_data = JSON.parse(file.read)
  end

  def [](key)
    @config_data[key]
  end

  def self.[](key)
    self.current[key]
  end

  def self.current
    @current ||= self.new
  end

end
