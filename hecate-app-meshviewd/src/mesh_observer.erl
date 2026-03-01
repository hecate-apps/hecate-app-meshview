%%% @doc Mesh observer — polls hecate-daemon for mesh state via erpc.
%%%
%%% This gen_server:
%%% 1. Discovers the hecate-daemon BEAM node on the same host
%%% 2. Polls mesh state every 10s via erpc:call/4
%%% 3. Caches the latest snapshot in gen_server state
%%% 4. Exposes cached state via get_snapshot/0, get_status/0, etc.
%%%
%%% If the daemon node is unreachable, retries discovery on next poll.
%%% No crash, no error — graceful degradation with disconnected state.
%%% @end
-module(mesh_observer).
-behaviour(gen_server).

-export([start_link/0]).
-export([get_snapshot/0, get_status/0, get_peers/0, get_node_id/0]).
-export([init/1, handle_info/2, handle_call/3, handle_cast/2, terminate/2]).

-define(DEFAULT_POLL_MS, 10000).

-record(state, {
    daemon_node :: atom() | undefined,
    connected :: boolean(),
    mesh_connected :: boolean(),
    node_id :: binary() | undefined,
    peers :: [map()],
    last_poll :: integer() | undefined,
    poll_ref :: reference() | undefined
}).

%%% Public API

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec get_snapshot() -> map().
get_snapshot() ->
    gen_server:call(?MODULE, get_snapshot).

-spec get_status() -> map().
get_status() ->
    gen_server:call(?MODULE, get_status).

-spec get_peers() -> [map()].
get_peers() ->
    gen_server:call(?MODULE, get_peers).

-spec get_node_id() -> binary() | undefined.
get_node_id() ->
    gen_server:call(?MODULE, get_node_id).

%%% gen_server callbacks

init([]) ->
    State = #state{
        daemon_node = undefined,
        connected = false,
        mesh_connected = false,
        node_id = undefined,
        peers = [],
        last_poll = undefined
    },
    Ref = schedule_poll(0),
    {ok, State#state{poll_ref = Ref}}.

handle_call(get_snapshot, _From, State) ->
    Snapshot = build_snapshot(State),
    {reply, Snapshot, State};
handle_call(get_status, _From, State) ->
    Status = #{
        daemon_connected => State#state.connected,
        mesh_connected => State#state.mesh_connected,
        daemon_node => format_node(State#state.daemon_node),
        last_poll => State#state.last_poll
    },
    {reply, Status, State};
handle_call(get_peers, _From, State) ->
    {reply, State#state.peers, State};
handle_call(get_node_id, _From, State) ->
    {reply, State#state.node_id, State};
handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(poll, State) ->
    NewState = do_poll(State),
    Ref = schedule_poll(poll_interval()),
    {noreply, NewState#state{poll_ref = Ref}};
handle_info(_Msg, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

%%% Internal

poll_interval() ->
    case application:get_env(hecate_app_meshviewd, poll_interval_ms) of
        {ok, Ms} -> Ms;
        undefined -> ?DEFAULT_POLL_MS
    end.

schedule_poll(DelayMs) ->
    erlang:send_after(DelayMs, self(), poll).

do_poll(State) ->
    Now = erlang:system_time(millisecond),
    case ensure_daemon_node(State) of
        {ok, Node, State1} ->
            poll_mesh_state(Node, State1#state{last_poll = Now});
        {error, _Reason, State1} ->
            State1#state{
                connected = false,
                mesh_connected = false,
                node_id = undefined,
                peers = [],
                last_poll = Now
            }
    end.

ensure_daemon_node(#state{daemon_node = undefined} = State) ->
    discover_daemon(State);
ensure_daemon_node(#state{daemon_node = Node} = State) ->
    case net_adm:ping(Node) of
        pong ->
            {ok, Node, State};
        pang ->
            logger:info("[mesh_observer] Lost connection to ~p, rediscovering", [Node]),
            discover_daemon(State#state{daemon_node = undefined})
    end.

discover_daemon(State) ->
    Hostname = hostname(),
    DaemonNode = list_to_atom("hecate@" ++ Hostname),
    case net_adm:ping(DaemonNode) of
        pong ->
            logger:info("[mesh_observer] Connected to daemon at ~p", [DaemonNode]),
            {ok, DaemonNode, State#state{daemon_node = DaemonNode, connected = true}};
        pang ->
            {error, daemon_unreachable, State#state{connected = false}}
    end.

hostname() ->
    NodeStr = atom_to_list(node()),
    case string:split(NodeStr, "@") of
        [_Name, Host] -> Host;
        _ -> net_adm:localhost()
    end.

poll_mesh_state(Node, State) ->
    MeshConnected = safe_erpc(Node, hecate_mesh, is_connected, []),
    NodeId = case MeshConnected of
        true -> fetch_node_id(Node);
        _ -> undefined
    end,
    Peers = case MeshConnected of
        true -> fetch_peers(Node);
        _ -> []
    end,
    State#state{
        connected = true,
        mesh_connected = MeshConnected =:= true,
        node_id = NodeId,
        peers = Peers
    }.

fetch_node_id(Node) ->
    case safe_erpc(Node, hecate_mesh, get_client, []) of
        {ok, Client} when is_pid(Client) ->
            case safe_erpc(Node, macula_peer, get_node_id, [Client]) of
                {ok, Id} -> Id;
                Id when is_binary(Id) -> Id;
                _ -> undefined
            end;
        _ ->
            undefined
    end.

fetch_peers(Node) ->
    case safe_erpc(Node, hecate_mesh, get_client, []) of
        {ok, Client} when is_pid(Client) ->
            case safe_erpc(Node, macula_peer, get_peers, [Client]) of
                {ok, PeerList} when is_list(PeerList) -> PeerList;
                PeerList when is_list(PeerList) -> PeerList;
                _ -> []
            end;
        _ ->
            []
    end.

safe_erpc(Node, Mod, Fun, Args) ->
    try
        erpc:call(Node, Mod, Fun, Args, 5000)
    catch
        error:{erpc, Reason} ->
            logger:debug("[mesh_observer] erpc to ~p:~p/~p failed: ~p",
                        [Mod, Fun, length(Args), Reason]),
            {error, Reason};
        Class:Reason ->
            logger:debug("[mesh_observer] erpc to ~p:~p/~p crashed: ~p:~p",
                        [Mod, Fun, length(Args), Class, Reason]),
            {error, {Class, Reason}}
    end.

build_snapshot(State) ->
    #{
        daemon_connected => State#state.connected,
        mesh_connected => State#state.mesh_connected,
        daemon_node => format_node(State#state.daemon_node),
        node_id => State#state.node_id,
        peer_count => length(State#state.peers),
        peers => State#state.peers,
        last_poll => State#state.last_poll
    }.

format_node(undefined) -> null;
format_node(Node) -> atom_to_binary(Node).
