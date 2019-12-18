defmodule Proj4 do
 #use Supervisor
       # use GenServer

      def func(args \\ []) do

        options = [switches: [file: :string],aliases: [f: :file]]
        {_,ar2,_} = OptionParser.parse(args,options)        

        n = List.first(ar2);        
        [n,n2] = if (n != "test") do
            n = String.to_integer(List.first(ar2))
            n2 = String.to_integer(List.last(ar2))
            [n,n2]
            else
            [100,3]
        end

        create(n,n2)

      end

      def create(n,n2) do

#***********  Server  ***********************
        {:ok,spid}=Server.Supervisor.start_link(2)
        #IO.inspect(spid) #supervisor's pid
        list=Supervisor.which_children(spid)
        server=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
          end)|>List.first()
        :global.register_name(:server,server)
        IO.inspect server

#**************************************************


#*******    User GENERATION    ****************************
        {:ok,cpid}=Client.Supervisor.start_link(n)
        #IO.inspect(cpid) #supervisor's pid
        list=Supervisor.which_children(cpid)
        user_list=(for x <- list, into: [] do
            {_,cid,_,_}=x
            cid
          end)
        #IO.inspect child_list
        user_list = Enum.reverse(user_list)
        Enum.each(user_list,fn(x)->Client.add_server(server,x) end)
##############################################################   

#*********** Tables ************************************

        #........................ User Table ..............................................
        :ets.new(:users, [:set, :public, :named_table])
        Enum.map(0..n,fn(x)->:ets.insert(:users, {Integer.to_string(x),Enum.at(user_list,x-1)}) end)
        #.....................................................................................
#....................... Tweet Table .................................................
        :ets.new(:tweetable,[:set, :public, :named_table])
        Enum.map(0..n,fn(x)->:ets.insert(:tweetable, {Integer.to_string(x),["basic tweet of #{x}"]}) end)
#.........................................................................................
#...................... Follower Table ..............................................
        follower_list = Enum.map(1..n,fn(x)->[Integer.to_string(rem(x+4,n))] end)
        :ets.new(:followers, [:set, :public, :named_table])
        Enum.map(0..n,fn(x)->:ets.insert(:followers, {Integer.to_string(x),Enum.at(follower_list,x-1)}) end)
#....................... Mention Table .......................................................................

          :ets.new(:mentions,[:set, :public, :named_table])
          Enum.map(0..n,fn(x)->:ets.insert(:mentions, {"@"<>Integer.to_string(x),["Iamuser@#{x}"]}) end)
#.....................  Hashtag Table ......................................................
        :ets.new(:hashtags,[:set, :public, :named_table])
#...........................................................................................
        #:timer.sleep(5000)
        Enum.map(user_list,fn(x)->Client.subscribe(x,n) end)
        :timer.sleep(5000)
        Enum.each(user_list,fn(x)->Client.generate_tweet(x,n2) end)
        #:timer.sleep(5000)
        Enum.each(0..n,fn(x)->Client.retweet(Integer.to_string(x),server) end)
        
        end

        def register(user1) do
                user = Integer.to_string(user1)
                ret = if :ets.lookup(:users,user) == [] do
                        {:ok,pid} = Client.start_link(user1)
                        :ets.insert(:users,{Integer.to_string(user1),pid})
                        :ets.insert(:tweetable,{Integer.to_string(user1),["Basic tweet of #{user}"]})
                        "User Registered"
                      else
                        "User Exist"
                      end
                ret
        end
        
        def subscribe(user,follow) do
                user = Integer.to_string(user)
                follow = Integer.to_string(follow)
                if :ets.lookup(:users,user)==[] do
                        "User dont exist"
                else
                        sub_list = :ets.lookup(:followers,user)|>List.first()|>Tuple.to_list()|>List.last()
                        if Enum.member?(sub_list,follow) do
                                "User #{user} is already following User #{follow}"
                        else
                                sub_list = sub_list++[follow]
                                :ets.delete(:followers,user)
                                :ets.insert(:followers,{user,sub_list})
                                "User #{user} is now following User #{follow}"
                        end
                end
                true
        end

        def hash_query(hashtag) do
                :ets.lookup(:hashtags,hashtag)
        end

        def mention_query(mention) do
                :ets.lookup(:mentions,mention)
        end        

        def delete_account(user) do
                user = Integer.to_string(user)
                if :ets.lookup(:users,user) == [] do
                        "User dont exist for deletion"
                else
                        :ets.delete(:users,user)
                        :ets.delete(:tweetable,user)
                        :ets.delete(:followers,user)
                        "User deleted"
                end
        end

        def retweet(user) do
                user = Integer.to_string(user)
                if :ets.lookup(:tweetable,user) == [] do
                        "User dont exist for retweeting"
                else
                        pid = :ets.lookup(:users,user)|>List.first()|>Tuple.to_list()|>List.last()
                        tweet = :ets.lookup(:tweetable,user)|>List.first()|>Tuple.to_list()|>List.last()|>Enum.random()
                        state = Client.get_state(pid)
                        spid = Map.get(state,:spid)
                        GenServer.cast(spid,{:publishtweet,user,tweet})
                        "User #{user} retweeting {#{tweet}}"
                end
        end
        

        def deleteall() do
        #        :ets.delete(:users)
                :ets.delete(:hashtags) 
                :ets.delete(:mentions)
                :ets.delete(:followers) 
                :ets.delete(:tweetable) 
        end

end

defmodule Server.Supervisor do
    use Supervisor
    def start_link(n) do
        {myInt, _} = :string.to_integer(to_charlist(n))
        Supervisor.start_link(__MODULE__,n )
    end

    def init(myInt) do
       children =Enum.map(1..myInt, fn(s) -> 
            #IO.puts "I am in supervisor init"
            worker(Server,[s],[id: "#{s}"])
            end)
        supervise(children, strategy: :one_for_one)
    end
end

defmodule Server do
    use GenServer

    def start_link(index) do
        GenServer.start_link(__MODULE__,index)
    end

    def init(index) do
        state = %{:node=>index,:user_list=>[],:hashtags=>[]}
        #IO.puts " Supervisor is created"
        {:ok,state}
    end

    def get_h_m(tweet) do
        hashtags = Regex.scan(~r/#[a-zA-Z0-9_]{1,10}/, tweet)|> List.flatten()
        mentions = Regex.scan(~r/@[a-zA-Z0-9_]{1,10}/, tweet)|> List.flatten()
        [hashtags,mentions]
    end


#**************** Handle tweet****************************************************************

    def handle_cast({:publishtweet,node,tweet},state) do
        #IO.puts "check2"
        [hashtags,mentions] = get_h_m(tweet)
        #IO.inspect node
        Enum.each(hashtags,fn(x)->handle_hashtags(x,tweet) end)
        Enum.each(mentions,fn(x)->handle_mentions(x,tweet) end)
        sub_list = :ets.lookup(:followers,node)|>List.first()|>Tuple.to_list()|>List.last()
        sub_list = sub_list++[node]
        #IO.inspect sub_list
        for i<- sub_list do
            add_tweet(i,tweet)
        end
        {:noreply,state}
    end

    def add_tweet(node,tweet) do
        tweet_list = :ets.lookup(:tweetable,node)|>List.first()|>Tuple.to_list()|>List.last()
        tweet_list =    if Enum.member?(tweet_list,tweet) do
                            tweet_list
                        else
                            tweet_list++[tweet]
                        end
        :ets.delete(:tweetable,node)
        :ets.insert(:tweetable,{node,tweet_list})
    end

    def handle_hashtags(hashtag,tweet) do
        entry = :ets.lookup(:hashtags,hashtag)
        if entry == [] do
            #IO.inspect hashtag
            :ets.insert(:hashtags,{hashtag,[tweet]})
        else
            tweet_list = Enum.at(List.first(entry)|>Tuple.to_list(),1)
            tweet_list = if Enum.member?(tweet_list,tweet) do
                            tweet_list
                        else
                            tweet_list++[tweet]
                        end
            :ets.delete(:hashtags,hashtag)
            :ets.insert(:hashtags,{hashtag,tweet_list})
        end
    end

    def handle_mentions(mention,tweet) do
        entry = :ets.lookup(:mentions,mention)
        if entry == [] do
            #IO.inspect hashtag
            :ets.insert(:mention,{mention,[tweet]})
        else
            tweet_list = Enum.at(List.first(entry)|>Tuple.to_list(),1)
            tweet_list = if Enum.member?(tweet_list,tweet) do
                            tweet_list
                        else
                            tweet_list++[tweet]
                        end
            :ets.delete(:mentions,mention)
            :ets.insert(:mentions,{mention,tweet_list})
        end
    end


    def handle_cast({:add_tolist,random,node},state) do
        #IO.puts "Node #{node} subs to Node #{random}"
        sub_list = :ets.lookup(:followers,node)|>List.first()|>Tuple.to_list()|>List.last()
        #IO.puts "Node #{random} subslist #{inspect(sub_list)}"
        if Enum.member?(sub_list,node) do
            {:noreply,state}
        else
            sub_list = sub_list++[node]
            :ets.delete(:followers,Integer.to_string(random))
            :ets.insert(:followers,{Integer.to_string(random),sub_list})
            {:noreply,state}
        end
    end
end



defmodule Client.Supervisor do
    use Supervisor
    def start_link(n) do
        {myInt, _} = :string.to_integer(to_charlist(n))
        Supervisor.start_link(__MODULE__,n )
    end
    def init(myInt) do
       children =Enum.map(1..myInt, fn(s) -> 
            #IO.puts "I am in supervisor init"
            worker(Client,[s],[id: "#{s}"]) 
            end)
        supervise(children, strategy: :one_for_one)
    end
end

defmodule Client do
    use GenServer
    def start_link(index) do
        GenServer.start_link(__MODULE__,index)
    end
    def init(index) do
        state = %{:node=>Integer.to_string(index),:spid=>[],:upid=>[]}
        #IO.puts " Node    #{index} is created"
        {:ok,state}
    end
    def generate_tweet(pid,n) do
        Enum.each(1..n,fn(x)->GenServer.cast(pid,{:gen_tweet,n}) end) 
    end
    def handle_cast({:gen_tweet,n},state) do
        #IO.puts "check1"
        spid = Map.get(state,:spid)
        node = Map.get(state,:node)
        #IO.puts "#{node} is generating tweets"
        random = :rand.uniform(n)
        Enum.map(1..n,fn(x)->
            GenServer.cast(spid,{:publishtweet,node," User #{node} is tweeting num #{x} with hashtag #Iamuser#{node} tagging @#{:rand.uniform(10)}"}) end)
        {:noreply,state}
    end
    def subscribe(pid,n) do
        random = :rand.uniform(n)
        if random==n do
            subscribe(pid,n)
        else
            GenServer.cast(pid,{:subscribe,random})
        end
    end
    def handle_cast({:subscribe,random},state) do
        #IO.puts "check1"
        spid = Map.get(state,:spid)
        node = Map.get(state,:node)
        GenServer.cast(spid,{:add_tolist,random,node})
        {:noreply,state}
    end
    def add_server(server,x) do
        GenServer.cast(x,{:server,server,x})
    end
    def handle_cast({:server,spid,upid},state) do
        state = Map.put(state,:spid,spid)
        state = Map.put(state,:upid,upid)
        #sIO.inspect state
        {:noreply,state}
    end
    def retweet(node,spid) do
        tweet = :ets.lookup(:tweetable,node)|>List.first()|>Tuple.to_list()|>List.last()|>Enum.random()
        #IO.puts "Node #{node} retweeting #{tweet}"
        GenServer.cast(spid,{:publishtweet,node,tweet})
    end
    def get_state(pid) do
        GenServer.call(pid, {:state})
    end
    def handle_call({:state},_from,state) do
        {:reply,state,state}
    end
end

Proj4.func(System.argv)
