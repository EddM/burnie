# To update crontab:
# whenever --update-crontab

job_type :burnie, 'cd /opt/burnie && /opt/burnie/burnie :task'

every 30.minutes do
  burnie "related"
end

every 1.day, :at => "1:00 pm" do
  burnie "gamethread"
end

every 1.day, :at => "9:00 am" do
  burnie "schedule"
  burnie "standings"
  burnie "playoffs"
end
