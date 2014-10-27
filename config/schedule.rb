# To update crontab:
# whenever --update-crontab

job_type :burnie, '/opt/burnie/burnie :task'

every 1.day, :at => "3:00 am" do
  burnie "gamethread"
end

every 1.day, :at => "9:00 am" do
  burnie "schedule"
  burnie "standings"
end
