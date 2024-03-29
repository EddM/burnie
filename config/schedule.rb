# frozen_string_literal: true

# To update crontab:
# whenever --update-crontab

job_type :burnie, "cd /opt/burnie && /opt/burnie/burnie :task"

every 1.day, at: "11:00 am" do
  burnie "gamethread"
  # burnie "playoffs"
  # burnie "summer_league:gamethread"
  # burnie "summer_league:schedule"
end

every 1.hour do
  burnie "standings"
  burnie "schedule"
end
