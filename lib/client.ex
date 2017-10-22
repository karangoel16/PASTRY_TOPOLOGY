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
                    state=routing_maker(state,name,name)
                    state=routing_maker(state,name,name_next)
                    list=elem(state,0)
                    state_temp=GenServer.call({x,Node.self()},{:state,1,1,1},:infinity)
                    rout_temp=elem(state_temp,2)
                    Enum.map(Map.values(list),fn(x)->
                        GenServer.cast({x,Node.self()},{:join,state,name,x,1})
                    end)
                    temp = Enum.map(Map.values(rout_temp),fn(x)->
                        if x != nil do
                            state=routing_maker(state,name,x) 
                            elem(state,2)
                        end
                    end)|>Enum.max(fn->elem(state,2) end)
                    state=Tuple.delete_at(state,2)|>Tuple.insert_at(2,temp)
                end)
                rout_temp=elem(state,0)
                temp = Enum.map(Map.values(rout_temp),fn(x)->
                    x=x|>Atom.to_string
                    if x != nil do
                        state=routing_maker(state,name,x) 
                        elem(state,2)
                    end
                end)|>Enum.max(fn->elem(state,2) end)
                state=Tuple.delete_at(state,2)|>Tuple.insert_at(2,temp)
                state=leaf_maker(state)
                Enum.map(Map.values(elem(state,0)),fn(x)->
                    GenServer.cast({x,Node.self()},{:join,state,name,x,1})
                end)
                Enum.map(Map.values(elem(state,1)),fn(x)->
                    GenServer.cast({x|>String.to_atom,Node.self},{:join,state,name,x|>String.to_atom,1})
                end)
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
                :join_state->
                        map=elem(state,2) #we will take values from the state and move them forward
                        Enum.map(Map.values(map),fn(x)->
                            state_key=GenServer.call({x|>String.to_atom,Node.self()},{:state,1,1,1},:infinity)
                            GenServer.cast({myname,Node.self()},{:join,state_key,myname,myname,1})
                        end)
                        map=elem(state,1) #we will take values from the state and move them forward
                        Enum.map(Map.values(map),fn(x)->
                            state_key=GenServer.call({x|>String.to_atom,Node.self()},{:state,1,1,1},:infinity)
                            GenServer.cast({myname,Node.self()},{:join,state_key,myname,myname,1})
                        end)
                        #Process.sleep(1000)
                        #GenServer.call({myname,Node.self()},{:join_state,key,nextId,myname})
                        {:reply,state,state}
                 #we are sending our own value back to the join function
        end
    end
    def handle_cast({choice,key,nextId,myname,jumps},state) do   
            case choice do
                :join->
                        state_temp=key
                        rout_temp=elem(state_temp,2)
                        name=myname|>Atom.to_string
                        temp = Enum.map(Map.values(rout_temp),fn(x)->
                            if x != nil do
                                state=routing_maker(state,name,x) 
                                elem(state,2)
                            end
                        end)|>Enum.max(fn->elem(state,2) end)
                        state=Tuple.delete_at(state,2)|>Tuple.insert_at(2,temp)
                        list=elem(state,0)
                        state=leaf_maker(state)
                        {:noreply,state}
                :route->
                            Process.sleep(10)
                            a=key |> Atom.to_string
                            b=myname |> Atom.to_string
                            if(a==b) do
                                Process.sleep(10)
                                GenServer.call({:Server,Node.self()},{:server,nextId,jumps},:infinity)
                            else 
                                Process.sleep(10)
                                leaf=elem(state,1)
                                routing=elem(state,2)
                                d=shl(a,b)
                                {l_min,l_max}=Enum.map(Map.values(leaf),fn(x)->
                                shl(b,x) 
                                end)|>Enum.min_max
                                if Enum.member?(Map.values(leaf),a) do
                                    {k,v}=Enum.map(Map.keys(leaf),fn(x)->
                                        {x,abs(shl(Map.get(leaf,x),a)-d)}
                                    end)|>Enum.min_by(fn {k,v}->v end)
                                    GenServer.cast({Map.get(leaf,k)|>String.to_atom,Node.self()},{:route,key,nextId,Map.get(leaf,k)|>String.to_atom,jumps+1})
                                else
                                    val=Enum.map(0..3, fn(x)->
                                        if(Map.get(routing,d*4+x) != nil) do
                                            #GenServer.cast({Map.get(routing,d*4+x)|>String.to_atom,Node.self()},{:route,key,nextId,Map.get(routing,d*4+x)|>String.to_atom,jumps+1})
                                            {x,d*4+x}
                                        end
                                        {-1,1}
                                    end) |> Map.new |> Map.delete(-1)
                                    if Map.values(val)|> length != 0 do
                                        Enum.map(Enum.take_random(Map.values(val),1),fn(x)->
                                            GenServer.cast({Map.get(routing,x)|>String.to_atom,Node.self()},{:route,key,nextId,Map.get(routing,x)|>String.to_atom,jumps+1})
                                        end)
                                    end 
                                    if Map.values(val)|> length == 0 do
                                        mer=Map.merge(leaf,routing)
                                        mer=Enum.map(Map.keys(elem(state,0)),fn(x)->
                                            {x,Map.get(elem(state,0),x)|>Atom.to_string}
                                        end)|>Map.new|>Map.merge(mer)
                                        val=Enum.max_by(Map.values(mer),fn(x)->shl(a,x)-d end)
                                        #GenServer.cast({val|>String.to_atom,Node.self()},{:route,key,nextId,val|>String.to_atom,jumps+1})
                                        Enum.map(Enum.take_random(Map.values(mer),1),fn(x)->
                                            GenServer.cast({x|>String.to_atom,Node.self()},{:route,key,nextId,x|>String.to_atom,jumps+1})
                                        end)
                                    end
                                end 
                            end
                        {:noreply,state}
                end
    end
    def routing_maker(state,name,name_next) do
        val= Enum.map(0..(String.length(name)),fn(x)->
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
                state=Tuple.delete_at(state,2)|>Tuple.insert_at(2,routing)
                list=elem(state,0)
                Enum.map(Map.values(list),fn(x)->
                    GenServer.cast({x,Node.self()},{:join,state,name,x,1})
                    GenServer.cast({name|>String.to_atom,Node.self()},{:join,state,x,name|>String.to_atom,1})
                end)
            end
        end
        state
    end
    def leaf_maker(state) do
        routing=elem(state,2)
        leaf=Enum.map(Enum.take(Enum.take(Map.keys(routing),length(Map.keys(routing))/2 |> round),-2),fn(x)->
            {x , Map.get(routing,x)}
         end) |>Map.new
         leaf=Enum.map(Enum.take(Enum.take(Map.keys(routing), -1 *(length(Map.keys(routing))/2 |> round)),2),fn(x)->
             {x,Map.get(routing,x)}
         end) |> Map.new |> Map.merge(leaf)
         state=Tuple.delete_at(state,1)|>Tuple.insert_at(1,leaf)
         state
    end
    def shl(a,b) do
        val= Enum.map(0..(String.length(a)),fn(x)->
            temp=String.slice(a,0..x)
            temp1=String.slice(b,0..x)
            if(temp==temp1) do
                temp1
            else
                ""
            end
        end)|>Enum.max|>String.length
        val
    end
end