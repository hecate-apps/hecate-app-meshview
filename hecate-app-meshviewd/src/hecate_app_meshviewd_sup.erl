%%% @doc Hecate MeshView top-level supervisor.
%%%
%%% Supervision tree:
%%% hecate_app_meshviewd_sup (one_for_one)
%%%   - app_meshviewd_plugin_registrar (transient worker)
%%%   - mesh_observer (permanent gen_server)
%%% @end
-module(hecate_app_meshviewd_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 60
    },
    ChildSpecs = [
        #{
            id => app_meshviewd_plugin_registrar,
            start => {app_meshviewd_plugin_registrar, start_link, []},
            restart => transient,
            type => worker
        },
        #{
            id => mesh_observer,
            start => {mesh_observer, start_link, []},
            restart => permanent,
            type => worker
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.
