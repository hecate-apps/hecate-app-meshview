%%% @doc Plugin manifest endpoint: GET /manifest
%%%
%%% Returns plugin metadata from priv/manifest.json for hecate-web discovery.
%%% The version field is overridden with the running application version.
%%% @end
-module(app_meshviewd_manifest_api).

-export([init/2]).

init(Req0, State) ->
    case cowboy_req:method(Req0) of
        <<"GET">> ->
            handle_get(Req0, State);
        _ ->
            Req1 = cowboy_req:reply(405, #{
                <<"content-type">> => <<"application/json">>
            }, <<"{\"ok\":false,\"error\":\"method_not_allowed\"}">>, Req0),
            {ok, Req1, State}
    end.

handle_get(Req0, State) ->
    case read_manifest() of
        {ok, Manifest} ->
            {ok, Vsn} = application:get_key(hecate_app_meshviewd, vsn),
            WithVersion = Manifest#{<<"version">> => list_to_binary(Vsn)},
            Body = json:encode(WithVersion),
            Req = cowboy_req:reply(200, #{
                <<"content-type">> => <<"application/json">>,
                <<"access-control-allow-origin">> => <<"*">>
            }, Body, Req0),
            {ok, Req, State};
        {error, Reason} ->
            logger:warning("[manifest_api] Failed to read manifest.json: ~p", [Reason]),
            Body = json:encode(#{ok => false, error => <<"manifest_not_found">>}),
            Req = cowboy_req:reply(500, #{
                <<"content-type">> => <<"application/json">>
            }, Body, Req0),
            {ok, Req, State}
    end.

read_manifest() ->
    PrivDir = code:priv_dir(hecate_app_meshviewd),
    Path = filename:join(PrivDir, "manifest.json"),
    case file:read_file(Path) of
        {ok, Bin} -> {ok, json:decode(Bin)};
        {error, Reason} -> {error, Reason}
    end.
