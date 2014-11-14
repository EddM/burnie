class RelatedSubredditsTask

  RelatedSubreddits = ["miamidolphins", "miamihurricanes", "letsgofish", "miamimls", "floridapanthers"]

  def call(client)
    @client = client
    update_sidebar
  end

  def top_links
    top_links = RedditKit.links(RelatedSubreddits.join("+")).select { |link| !link.title.match(/game thread/) }.first(5)
  end

  def update_sidebar
    subreddit_attributes = @client.subreddit_attributes(Configuration["subreddit"])
    sidebar_text = subreddit_attributes[:description]
    links_markdown = "###Top Related Sub Links\n\n"

    top_links.each_with_index do |link, i|
      links_markdown << "#{i + 1}. [#{link.title}](#{link.permalink})\n"
    end

    sidebar_text.gsub!(/###Top Related Sub Links(.*)###Subreddit Rules/m, "#{links_markdown}\n\n###Subreddit Rules")

    @client.update_subreddit(Configuration["subreddit"], {
      :description => sidebar_text
    })
  end

end
