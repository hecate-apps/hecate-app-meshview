%%% @doc Path utilities for hecate-app-meshviewd.
%%%
%%% Provides purpose-specific path functions for the namespaced
%%% directory layout under ~/.hecate/hecate-app-meshviewd/:
%%%
%%%   sockets/      - Unix domain sockets
%%%   run/          - PID and state files
%%%
%%% The base directory is configured via
%%% {hecate_app_meshviewd, [{data_dir, Path}]}.
%%% Default: ~/.hecate/hecate-app-meshviewd
%%% @end
-module(app_meshviewd_paths).

-export([
    base_dir/0,
    socket_dir/0,
    socket_path/1,
    run_dir/0,
    run_path/1,
    ensure_layout/0
]).

-spec base_dir() -> file:filename().
base_dir() ->
    case application:get_env(hecate_app_meshviewd, data_dir) of
        {ok, Dir} -> expand_path(Dir);
        undefined -> expand_path("~/.hecate/hecate-app-meshviewd")
    end.

-spec socket_dir() -> file:filename().
socket_dir() ->
    filename:join(base_dir(), "sockets").

-spec socket_path(string() | binary()) -> file:filename().
socket_path(Name) ->
    filename:join(socket_dir(), Name).

-spec run_dir() -> file:filename().
run_dir() ->
    filename:join(base_dir(), "run").

-spec run_path(string() | binary()) -> file:filename().
run_path(Name) ->
    filename:join(run_dir(), Name).

-spec ensure_layout() -> ok.
ensure_layout() ->
    Dirs = [
        socket_dir(),
        run_dir()
    ],
    lists:foreach(fun(Dir) -> ok = filelib:ensure_path(Dir) end, Dirs).

%%% Internal

expand_path("~/" ++ Rest) ->
    filename:join(os:getenv("HOME"), Rest);
expand_path(Path) ->
    Path.
