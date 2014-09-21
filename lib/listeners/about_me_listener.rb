class AboutMeListener < Listener

  def pattern
    /(who is|who's)(.*)(this)?(.*)burnie(.)bot/i
  end

  def call(comment, match_data)
    comment = "I'm **Burnie_Bot**! /r/Heat's very own mascot. I take care of the boring stuff like updating the subreddit's sidebar with schedules and division standings, but you can also ask questions of my encyclopedic NBA stat knowledgebase. Such as *\"What were Dwyane Wade's stats last year?\"* or *\"What are Mario Chalmers' career stats?\"*

Got any feedback, suggestions or bug reports? Reply to me or message my creator, /u/BLITZCRUNK123."

    send_reply(comment, comment_body)
  end

end
