require 'json'
require 'open-uri'
require 'snoo'

require './lib/tasks/schedule.rb'

if ARGV[0] == "schedule"
  task = ScheduleTask.new
  task.call(Time.now.year, 10, 15)
end
