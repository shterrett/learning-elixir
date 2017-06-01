defmodule Metex.Worker do

  def loop do
    receive do
      { sender_pid, location } ->
        send(sender_pid, { :ok, temperature_of(location) })
      _ -> IO.puts "don't know how to process this message"
    end

    loop()
  end

  def temperature_of(location) do
    results = url_for(location)
              |> HTTPoison.get
              |> parse_response

    case results do
      { :ok, temp } ->
        "#{location}: #{temp}°C"
      :error ->
        "#{location} not found"
    end
  end

  defp url_for(location) do
    "http://api.openweathermap.org/data/2.5/weather?q=#{URI.encode(location)}&appid=#{api_key()}"
  end

  defp parse_response({ :ok, %HTTPoison.Response{ body: body, status_code: 200 } }) do
    body
    |> JSON.decode!
    |> compute_temperature
  end
  defp parse_response(_), do: :error

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      { :ok, temp }
    rescue
      _ -> :error
    end
  end

  defp api_key, do: Application.get_env(:metex, :open_weather_map)[:api_key]
end
