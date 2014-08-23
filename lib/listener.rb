class Listener
  attr_reader :client

  def initialize(client, comment)
    if comment && match_data = comment["body"].match(pattern)
      @client = client
      call(comment, match_data)
    end
  end

  def call(comment, match_data)
    raise
  end

  def send_reply(comment, body)
    if comment && body
      new_comment = client.submit_comment comment["name"], body
      puts " + Replied to #{comment["id"]}"
      new_comment
    end
  end

end
