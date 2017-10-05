#https://gist.github.com/jisaacstone/7a698ad05e61a15b4d28
defmodule Project3.Exdistutils do
    def start_distributed(appname,server\\:error) do
      unless Node.alive?() do
        local_node_name = generate_name(appname,server)
        {:ok, _} = Node.start(local_node_name)
      end
      cookie = Application.get_env(appname, :cookie)
      Node.set_cookie(cookie)
    end
  
    def generate_name(appname,server) do
      {:ok,iplist}=:inet.getif()
      machine = Application.get_env(appname, :machine, iplist|>List.first|>Tuple.to_list|>List.first|>Tuple.to_list|>Enum.join("."))
      hex=
        case server do
        :error-> ""
        :ok->  :erlang.monotonic_time() |>
              :erlang.phash2(256) |>
              Integer.to_string(16)
        end
      String.to_atom("#{appname}#{hex}@#{machine}")
    end
  end