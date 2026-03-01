%%% @doc Hecate MeshView daemon application.
%%%
%%% On startup:
%%% 1. Ensures the namespace directory layout exists
%%% 2. Starts Cowboy on a Unix domain socket
%%% 3. Registers with hecate-daemon (when available)
%%% @end
-module(hecate_app_meshviewd_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    ok = app_meshviewd_paths:ensure_layout(),
    ok = start_cowboy(),
    logger:info("[hecate_app_meshviewd] Started, socket at ~s",
                [app_meshviewd_paths:socket_path("api.sock")]),
    hecate_app_meshviewd_sup:start_link().

stop(_State) ->
    ok = cowboy:stop_listener(app_meshviewd_http),
    cleanup_socket(),
    ok.

%%% Internal

start_cowboy() ->
    SocketPath = app_meshviewd_paths:socket_path("api.sock"),
    cleanup_socket_file(SocketPath),
    StaticDir = static_dir(),
    Routes = [
        {"/health", app_meshviewd_health_api, []},
        {"/manifest", app_meshviewd_manifest_api, []},
        {"/api/mesh/status", mesh_status_api, []},
        {"/ui/[...]", cowboy_static, {dir, StaticDir, [{mimetypes, cow_mimetypes, all}]}}
    ],
    Dispatch = cowboy_router:compile([{'_', Routes}]),
    TransOpts = #{
        socket_opts => [{ifaddr, {local, SocketPath}}],
        num_acceptors => 5
    },
    ProtoOpts = #{
        env => #{dispatch => Dispatch}
    },
    {ok, _} = cowboy:start_clear(app_meshviewd_http, TransOpts, ProtoOpts),
    ok.

static_dir() ->
    PrivDir = code:priv_dir(hecate_app_meshviewd),
    filename:join(PrivDir, "static").

cleanup_socket() ->
    SocketPath = app_meshviewd_paths:socket_path("api.sock"),
    cleanup_socket_file(SocketPath).

cleanup_socket_file(Path) ->
    case file:delete(Path) of
        ok -> ok;
        {error, enoent} -> ok;
        {error, Reason} ->
            logger:warning("[hecate_app_meshviewd] Failed to remove socket ~s: ~p",
                          [Path, Reason]),
            ok
    end.
