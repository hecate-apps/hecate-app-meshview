%%% @doc Shared API utilities for MeshView Cowboy handlers.
%%%
%%% Common functions used by all API handlers.
%%% @end
-module(app_meshviewd_api_utils).

-export([json_response/3, json_ok/2, json_error/3]).
-export([format_error/1]).
-export([method_not_allowed/1]).

-spec json_response(non_neg_integer(), map(), cowboy_req:req()) ->
    {ok, cowboy_req:req(), []}.
json_response(StatusCode, Body, Req0) ->
    JsonBody = json:encode(Body),
    Req = cowboy_req:reply(StatusCode, #{
        <<"content-type">> => <<"application/json">>,
        <<"access-control-allow-origin">> => <<"*">>
    }, JsonBody, Req0),
    {ok, Req, []}.

-spec json_ok(map(), cowboy_req:req()) -> {ok, cowboy_req:req(), []}.
json_ok(Result, Req) ->
    json_response(200, maps:merge(#{ok => true}, Result), Req).

-spec json_error(non_neg_integer(), term(), cowboy_req:req()) ->
    {ok, cowboy_req:req(), []}.
json_error(StatusCode, Reason, Req) ->
    json_response(StatusCode, #{ok => false, error => format_error(Reason)}, Req).

-spec method_not_allowed(cowboy_req:req()) -> {ok, cowboy_req:req(), []}.
method_not_allowed(Req) ->
    json_error(405, <<"Method not allowed">>, Req).

-spec format_error(term()) -> binary().
format_error(Reason) when is_binary(Reason) -> Reason;
format_error(Reason) when is_atom(Reason) -> atom_to_binary(Reason);
format_error(Reason) ->
    iolist_to_binary(io_lib:format("~p", [Reason])).
