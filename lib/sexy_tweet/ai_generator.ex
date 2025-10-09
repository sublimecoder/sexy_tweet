defmodule SexyTweet.AIGenerator do
  @openai System.get_env("OPENAI_API_KEY")

  def generate_from_history(tweets, n \\ 5) do
    examples =
      tweets
      |> Enum.take(8)
      |> Enum.map(& &1.text)
      |> Enum.join("\n- ")

    prompt = """
    Write #{n} short, sexy tweets in the same tone as these examples:
    - #{examples}

    Rules:
    - Max 280 characters each.
    - No hashtags unless natural.
    - Vary structure & rhythm.
    - Return as a plain list, one per line, no numbering.
    """

    {:ok, resp} =
      Req.post(
        url: "https://api.openai.com/v1/chat/completions",
        headers: [{"authorization", "Bearer #{@openai}"}, {"content-type", "application/json"}],
        json: %{
          model: "gpt-4o-mini",
          messages: [%{role: "user", content: prompt}],
          temperature: 0.9
        }
      )

    text =
      resp.body
      |> get_in(["choices", Access.at(0), "message", "content"])
      |> to_string()

    text
    |> String.split("\n", trim: true)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.trim_leading(&1, "- "))
  end
end
