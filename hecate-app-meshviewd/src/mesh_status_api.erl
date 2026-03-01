%%% @doc Mesh status API endpoint: GET /api/mesh/status
%%%
%%% Returns the cached mesh snapshot from mesh_observer.
%%% @end
-module(mesh_status_api).

-export([init/2]).

init(Req0, _State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            Snapshot = mesh_observer:get_snapshot(),
            app_meshviewd_api_utils:json_ok(Snapshot, Req0);
        _ ->
            app_meshviewd_api_utils:method_not_allowed(Req0)
    end.
