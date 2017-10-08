defmodule Project3.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,:ok,name: args)
        #loop()
    end

    def init(:ok) do
        {:ok,{{},%{}}}
    end
    def handle_call({choice,key,nextId},_from,state) do
        case choice do
            :forward->
                curr_id=key#:crypto.hash(:sha,name)|>Base.encode16|>Convertat.from_base(16) |> Convertat.to_base(4)
                leaf_set=elem(state,1)#TODO check the MapSet Position in State
                route=Enum.map(String.length(curr_id)-2..0,fn(x)->
                     temp=String.slice(curr_id,0..x)
                     if(Map.get(leaf_set,temp,-1)!=-1) do
                         temp
                     end
                end)|>Enum.max
                case route do
                    nil->#TODO we will call delivery then
                         {:reply,"deliver",state}
                    _->GenServer.call({Map.get(leaf_set,route)|>Integer.to_string|>String.to_atom,Node.self()},{:forward,key,Map.get(leaf_set,route),:infinite})
                        #we will call route message here
                end
        end
    end
end