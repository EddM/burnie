# To update crontab:
# whenever --update-crontab

job_type :burnie, 'cd /opt/burnie && /opt/burnie/burnie :task'

every 30.minutes do
  burnie "related"
end

every 1.day, :at => "1:00 pm" do
  burnie "gamethread"
end

every 1.day, :at => "8:00 am" do
  burnie "playoffs"
end

every 1.day, :at => "9:00 am" do
  burnie "standings"
end

every 1.day, :at => "10:00 am" do
  burnie "schedule"
end
