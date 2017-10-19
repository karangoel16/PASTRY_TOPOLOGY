defmodule Project3 do
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end

  def init(args) do
    map= Map.new Enum.map(0..(args-1),fn(x)->
      map=Map.put(%{},x,:crypto.hash(:sha,x|>Integer.to_string)|>Base.encode16|>Convertat.from_base(16) |> Convertat.to_base(2)|>String.slice(0..127)|>Convertat.from_base(2)|>Convertat.to_base(4)|>String.to_atom)
      Project3.Client.start_link(Map.get(map,x))
      {x , Map.get(map,x)}
    end)
    Enum.map(0..(args-1),fn(x)->
      Enum.map(Enum.take_random(0..(args-1),4),fn(y)->
        if x != y do
        GenServer.call({Map.get(map,x),Node.self()},{:test,Map.get(map,x),y,""},:infinity)
        end
      end)
    end)
    Enum.map(0..(args-1),fn(x)->
      GenServer.call({Map.get(map,x),Node.self()},{:link,Map.get(map,x),"",""},:infinity)
    end)
    """
    Enum.map(0..args-1,fn(x)->
      GenServer.call({Map.get(map,x),Node.self()},{:join,Map.get(map,x),1},:infinity)
    end)
    """
    Enum.map(Map.values(map),fn(x)->
      GenServer.call({x,Node.self()},{:join_state,1,1,x})
    end)   
    {:ok,map}
  end
  
  def main(args\\[]) do
    Project3.Exdistutils.start_distributed(:project3)
    number_of_nodes=elem(args|>List.to_tuple,0)|>String.to_integer
    number_of_req= elem(args|>List.to_tuple,1) |>String.to_integer
    #start_link(number_of_nodes,number_of_req) #this is to add server in our project
    #loop()
    map= Map.new Enum.map(0..(number_of_nodes-1),fn(x)->
      map=Map.put(%{},x,:crypto.hash(:sha,x|>Integer.to_string)|>Base.encode16|>Convertat.from_base(16) |> Convertat.to_base(2)|>String.slice(0..127)|>Convertat.from_base(2)|>Convertat.to_base(4)|>String.to_atom)
      Project3.Client.start_link(Map.get(map,x))
      {x , Map.get(map,x)}
    end)
    Enum.map(0..(number_of_nodes-1),fn(x)->
      Enum.map(Enum.take_random(0..(number_of_nodes-1),4),fn(y)->
        if x != y do
        GenServer.call({Map.get(map,x),Node.self()},{:test,Map.get(map,x),y,""},:infinity)
        end
      end)
    end)
    Enum.map(0..(number_of_nodes-1),fn(x)->
      GenServer.call({Map.get(map,x),Node.self()},{:link,Map.get(map,x),"",""},:infinity)
    end)
    """
    Enum.map(0..args-1,fn(x)->
      GenServer.call({Map.get(map,x),Node.self()},{:join,Map.get(map,x),1},:infinity)
    end)
    """
    spawn(fn-> loop(map) end)
    IO.puts "Starting to send message"
    Enum.map(0..number_of_req,fn(x)->
      from = :random.uniform(number_of_nodes)
      to = :random.uniform(number_of_nodes)
      GenServer.cast({Map.get(map,from),Node.self()},{:route,Map.get(map,to),:random.uniform(1000),Map.get(map,from)})
    end)
    Process.sleep(1_000_000)
  end

  def handle_call({choice,name},_from,state) do
    case choice do
      :proxy->
        route=Enum.map(1..state-1,fn(x)->
            if GenServer.whereis({rem((x+name),(state))|>Integer.to_string|>String.to_atom,Node.self()})!=nil do
                rem((x+name),(state))
              end
            end
          )|>MapSet.new|>MapSet.delete(nil)|>MapSet.to_list|>Enum.min_by(fn(x)->abs(x-name)end,fn->nil end)
        {:reply,route,state}
      _->IO.puts "Undefined call value in Server"
       {:reply,state,state};
    end
  end

  def loop(map) do
    Enum.map(Map.values(map),fn(x)->
      GenServer.call({x,Node.self()},{:join_state,1,1,x})
    end)
    Process.sleep(1000)
    loop(map)
  end
end
