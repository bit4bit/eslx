defprotocol ESLx.ConnectionDetails do
  def host(details)
  def port(details)
  def username(details)
  def password(details)
end

defimpl ESLx.ConnectionDetails, for: URI do
  def host(%{host: host}) do
    host
  end

  def port(%{port: port}) do
    port
  end

  def username(%{userinfo: userinfo}) do
    case String.split(userinfo, ":", parts: 2) do
      ["", _] ->
        nil

      [username, _] ->
        username

      username ->
        username
    end
  end

  def password(%{userinfo: userinfo}) do
    case String.split(userinfo, ":", parts: 2) do
      [_, password] ->
        password

      _ ->
        nil
    end
  end
end
