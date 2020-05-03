-module(mcat).
-export([start_server/1]).

-record(client, {
  process,
  name
}).

start_server(Port) ->
  Pid = spawn_link(fun() ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [{active, false}]),
    Relay = spawn(fun() -> relay([]) end),
    spawn(fun() -> accept(Relay, ListenSocket) end),
    timer:sleep(infinity) end),
  {ok, Pid}.

accept(Relay, ListenSocket) ->
  {ok, AcceptSocket} = gen_tcp:accept(ListenSocket),
  spawn(fun() -> accept(Relay, ListenSocket) end),
  register_client(Relay, AcceptSocket).

relay(Clients) when is_list(Clients) ->
  receive
    {connect, Client} ->
      relay([Client|Clients]);
    {relay, Message, Client} ->
      lists:map(fun(It) -> It#client.process ! {message, "<" ++ Client#client.name ++ "> " ++ Message} end,
        lists:filter(fun(It) -> It#client.process =/= Client#client.process end, Clients)),
      relay(Clients);
    Else ->
      io:format(Else),
      relay(Clients)
  end.

register_client(Relay, Socket) ->
  gen_tcp:send(Socket, "Enter your name: "),
  inet:setopts(Socket, [{active, once}]),
  receive
    {tcp, Socket, Name} ->
      Client = #client{process = self(), name = lists:reverse(tl(lists:reverse(Name)))},
      Relay ! {connect, Client},
      handle_connection(Relay, Socket, Client)
  end.

handle_connection(Relay, Socket, Client) ->
  inet:setopts(Socket, [{active, once}]),
  receive
    {tcp, Socket, <<"quit", _/binary>>} ->
      gen_tcp:close(Socket);
    {tcp, Socket, Msg} ->
      Relay ! {relay, Msg, Client},
      handle_connection(Relay, Socket, Client);
    {message, Msg} ->
      gen_tcp:send(Socket, Msg),
      handle_connection(Relay, Socket, Client);
    _ ->
      io:format("That's enexpected"),
      handle_connection(Relay, Socket, Client)
  end.
