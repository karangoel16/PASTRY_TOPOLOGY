defmodule Project3.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
        #loop()
    end

    def init(:ok) do
        {:ok,{{},%{}}}
    end
end