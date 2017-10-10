defmodule Project3.Client do
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__,{:ok,args},name: args)
    end

    def init({:ok,args}) do
        {:ok,{%{},%{},%{}}} #elem 0 is neighbouring list #elem 1 is leaf set
    end
    
    def handle_call({choice,key,nextId,myname},_from,state) do
        case choice do
            :test->
                list=elem(state,0)
                list=Map.put(list,nextId,:crypto.hash(:sha,nextId|>Integer.to_string)|>Base.encode16|>Convertat.from_base(16) |> Convertat.to_base(2)|>String.slice(0..127)|>Convertat.from_base(2)|>Convertat.to_base(4)|>String.to_atom)
                state=Tuple.delete_at(state,0)
                state=Tuple.insert_at(state,0,list)
                {:reply,"",state}
            :link->
                name=key|>Atom.to_string
                Enum.map(Map.values(elem(state,0)),fn(x)->
                    name_next=x|>Atom.to_string
                    state=routing_maker(state,name,name_next)
                    list=elem(state,0)
                    state_temp=GenServer.call({x,Node.self()},{:state,1,1,1},:infinity)
                    rout_temp=elem(state_temp,2)
                    Enum.map(Map.values(list),fn(x)->
                        GenServer.cast({x,Node.self()},{:join,state,name,x})
                    end)
                    temp = Enum.map(Map.values(rout_temp),fn(x)->
                        if x != nil do
                            state=routing_maker(state,name,x) 
                            elem(state,2)
                        end
                    end)|>Enum.max(fn->elem(state,2) end)
                    state=Tuple.delete_at(state,2)|>Tuple.append(temp)
                end)
                rout_temp=elem(state,0)
                temp = Enum.map(Map.values(rout_temp),fn(x)->
                    x=x|>Atom.to_string
                    if x != nil do
                        state=routing_maker(state,name,x) 
                        elem(state,2)
                    end
                end)|>Enum.max(fn->elem(state,2) end)
                state=Tuple.delete_at(state,2)|>Tuple.append(temp)
                {:reply,state,state}
            :forward->
                curr_id=key|>Atom.to_string#:crypto.hash(:sha,name)|>Base.encode16|>Convertat.from_base(16) |> Convertat.to_base(4)
                leaf_set=elem(state,1)#TODO check the MapSet Position in State
                route= Enum.map(String.length(curr_id)-2..0,fn(x)->
                    temp=String.slice(curr_id,0..x)
                    if(Map.get(leaf_set,temp,-1)!=-1) do
                        temp
                    end
                end)|>Enum.max
                case route do
                    nil->#TODO we will call delivery then
                         {:reply,elem(state,1),state}#TODO we need to make table of routing and send it back when we have the maximum possible element
                    _-> 
                        #GenServer.call({Map.get(leaf_set,route)|>Integer.to_string|>String.to_atom,Node.self()},{:forward,key,Map.get(leaf_set,route)},:infinite)
                        #we will call route message here
                        {:reply,elem(state,1),state}
                end
                :state->
                    {:reply,state,state}
                 #we are sending our own value back to the join function
        end
    end
    def handle_cast({:join,key,nextId,myname},state) do   
            state_temp=key
            rout_temp=elem(state_temp,2)
            name=myname|>Atom.to_string
            temp = Enum.map(Map.values(rout_temp),fn(x)->
                if x != nil do
                    state=routing_maker(state,name,x) 
                    elem(state,2)
                end
            end)|>Enum.max(fn->elem(state,2) end)
            state=Tuple.delete_at(state,2)|>Tuple.append(temp)
            list=elem(state,0)
            {:noreply,state}
    end
    def routing_maker(state,name,name_next) do
        val= Enum.map((String.length(name))..0,fn(x)->
            temp=String.slice(name,0..x)
            temp1=String.slice(name_next,0..x)
            if(temp==temp1) do
                temp1
            else
                ""
            end
        end)|>Enum.max
        routing=elem(state,2)
        if val != nil do
            temp=String.at(name_next,String.length(val))
            if temp != nil and temp != name and Map.get(routing,String.length(val)*4+String.to_integer(temp)) == nil do
                temp=temp|>String.to_integer
                routing=Map.put(routing,(String.length(val))*4+temp,name_next)
                state=Tuple.delete_at(state,2)|>Tuple.append(routing)
                list=elem(state,0)
                Enum.map(Map.values(list),fn(x)->
                    GenServer.cast({x,Node.self()},{:join,state,name,x})
                    GenServer.cast({name|>String.to_atom,Node.self()},{:join,state,x,name|>String.to_atom})
                end)
            end
        end
        state
    end

end