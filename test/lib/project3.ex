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
    IO.inspect Enum.map(1..number_of_nodes,fn(x)->Project3.Client.start_link(Integer.to_string(x,2)|>String.to_atom)end)
    #loop()
  end
  def loop do
    Process.sleep(100000)    
  end
end
