%% -*- mode: erlang; tab-width: 4; indent-tabs-mode: 1; st-rulers: [70] -*-
%% vim: ts=4 sw=4 ft=erlang noet
%%%-------------------------------------------------------------------
%%% @author Andrew Bennett <andrew@pixid.com>
%%% @copyright 2014-2015, Andrew Bennett
%%% @doc
%%%
%%% @end
%%% Created :  20 Jul 2015 by Andrew Bennett <andrew@pixid.com>
%%%-------------------------------------------------------------------
-module(jose).

%% API
-export([decode/1]).
-export([encode/1]).
-export([json_module/0]).
-export([json_module/1]).
-export([start/0]).

-define(TAB, jose_jwa).

-define(MAYBE_START_JOSE(F), try
	F
catch
	_:_ ->
		_ = jose:start(),
		F
end).

%%====================================================================
%% API functions
%%====================================================================

decode(Binary) ->
	JSONModule = json_module(),
	JSONModule:decode(Binary).

encode(Term) ->
	JSONModule = json_module(),
	JSONModule:encode(Term).

json_module() ->
	?MAYBE_START_JOSE(ets:lookup_element(?TAB, json_module, 2)).

json_module(JSONModule) when is_atom(JSONModule) ->
	?MAYBE_START_JOSE(jose_server:json_module(JSONModule)).

start() ->
	case application:ensure_all_started(?MODULE) of
		{ok, _} ->
			ok;
		StartError ->
			StartError
	end.

%%%-------------------------------------------------------------------
%%% Internal functions
%%%-------------------------------------------------------------------
