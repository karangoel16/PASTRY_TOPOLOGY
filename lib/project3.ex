defmodule Project3 do
  use GenServer
  
  def start_link(args) do
    GenServer.start_link(__MODULE__,args,name: :Server)
  end

  def init(args) do
    number_of_nodes=elem(args|>List.to_tuple,0)|>String.to_integer
    number_of_req= elem(args|>List.to_tuple,1) |>String.to_integer
    map= Map.new Enum.map(0..(number_of_nodes-1),fn(x)->
      map=Map.put(%{},x,:crypto.hash(:sha,x|>Integer.to_string)|>Base.encode16|>Convertat.from_base(16) |> Convertat.to_base(2)|>String.slice(0..127)|>Convertat.from_base(2)|>Convertat.to_base(4)|>String.to_atom)
      Project3.Client.start_link(Map.get(map,x))
      {x , Map.get(map,x)}
    end)
    Enum.map(0..(number_of_nodes-1),fn(x)->
      Enum.map(Enum.take_random(0..(number_of_nodes-1),4),fn(y)->
        if x != y do
        GenServer.call({Map.get(map,x),Node.self()},{:test,Map.get(map,x),y,""},:infinity)
        GenServer.call({Map.get(map,y),Node.self()},{:test,Map.get(map,y),x,""},:infinity)
        end
      end)
    end)
    Enum.map(0..(number_of_nodes-1),fn(x)->
      GenServer.call({Map.get(map,x),Node.self()},{:link,Map.get(map,x),"",""},:infinity)
      GenServer.call({Map.get(map,x),Node.self()},{:join_state,"","",Map.get(map,x)},:infinity)
    end)
    IO.puts "Starting to send message"
    Enum.map(0..number_of_req,fn(x)->
      Enum.map(0..(number_of_nodes-1),fn(y)->
        to = :random.uniform(number_of_nodes)
        GenServer.cast({Map.get(map,y),Node.self()},{:route,Map.get(map,to),:crypto.hash(:sha,(x+y+to+:random.uniform(100))|>Integer.to_string),Map.get(map,y),0})
      end)
    end)  
    {:ok,{map,number_of_nodes,number_of_req,%{}}}
  end
  
  def main(args\\[]) do
    Project3.Exdistutils.start_distributed(:project3)

    start_link(args) #this is to add server in our project
    #loop()

    Process.sleep(1_000_000)
  end

  def handle_call({choice,name,jumps},_from,state) do
    case choice do
      :proxy->
        route=Enum.map(1..state-1,fn(x)->
            if GenServer.whereis({rem((x+name),(state))|>Integer.to_string|>String.to_atom,Node.self()})!=nil do
                rem((x+name),(state))
              end
            end
          )|>MapSet.new|>MapSet.delete(nil)|>MapSet.to_list|>Enum.min_by(fn(x)->abs(x-name)end,fn->nil end)
        {:reply,route,state}
      :server->
        maps=elem(state,3)
        if(length(Map.values(maps)) >= elem(state,1)*elem(state,2)*0.7) do
          IO.puts Enum.sum(Map.values(maps))/(Map.values(maps)|>length)
          Enum.map(Map.values(elem(state,0)),fn(x)->
            GenServer.stop({x,Node.self()})
          end)
          Process.exit(self(),:normal)
        else
            if Map.get(maps,name) == nil do
              IO.puts length(Map.values(maps))
            end
            maps=Map.put_new(maps,name,jumps)
            state=Tuple.delete_at(state,3)|>Tuple.insert_at(3,maps)
        end
        {:reply,"",state}
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
