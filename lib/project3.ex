defmodule Project3 do
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end

  def init(args) do 
    {:ok,args}
  end
  
  def main(args\\[]) do
    Project3.Exdistutils.start_distributed(:project3)
    number_of_nodes=elem(args|>List.to_tuple,0)|>String.to_integer
    start_link(number_of_nodes) #this is to add server in our project
    IO.inspect Enum.map(0..number_of_nodes,fn(x)->Project3.Client.start_link(Integer.to_string(x)|>String.to_atom)end)
    Enum.map(0..number_of_nodes,fn(x)->
        GenServer.call({x|>Integer.to_string|>String.to_atom,Node.self()},{:link,x,x+1},:infinite)
    end)
    Enum.map(1..number_of_nodes,fn(x)->
        GenServer.call({x|>Integer.to_string|>String.to_atom,Node.self()},{:link,x,x-1},:infinite)
    end)
    
    loop()
  end

  def handle_call({choice,name},_from,state) do
    case choice do
      :proxy->
        route=Enum.map(1..state-1,fn(x)->
            if GenServer.whereis({rem((x+name),(state))|>Integer.to_string|>String.to_atom,Node.self()})!=nil do
                rem((x+name),(state))
              end
            end
          )|>Enum.min_by(fn(x)->abs(x-name)end)
        {:reply,route,state}
      _->IO.puts "Undefined call value in Server"
       {:reply,":error",state};
    end
  end

  def loop do
    Process.sleep(100000)    
  end
end
