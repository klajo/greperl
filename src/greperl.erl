%%%===================================================================
%%% Copyright (c) 2014, Klas Johansson
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are
%%% met:
%%%
%%%     * Redistributions of source code must retain the above copyright
%%%       notice, this list of conditions and the following disclaimer.
%%%
%%%     * Redistributions in binary form must reproduce the above copyright
%%%       notice, this list of conditions and the following disclaimer in
%%%       the documentation and/or other materials provided with the
%%%       distribution.
%%%
%%%     * Neither the name of the copyright holder nor the names of its
%%%       contributors may be used to endorse or promote products derived
%%%       from this software without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
%%% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
%%% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
%%% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%%% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%%% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
%%% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
%%% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
%%% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
%%% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%%% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%%===================================================================

%%% @author Klas Johansson
%%% @copyright 2014, Klas Johansson
%%% @doc Convert files with erlang tuples into something grep:able
%%%
%%% `greperl' can be used both from a shell through the `bin/greperl'
%%% escript, or the Erlang API.  For command line options, see:
%%% ```
%%% $ ./bin/greperl -h
%%% Usage: greperl [-h] [-s <separator>] [--no-quote-strings] <file>
%%%
%%%   -h, --help          show help
%%%   -s, --separator     set key-value separator
%%%   --no-quote-strings  do not quote strings
%%%   <file>              name of file which can be read using file:consult/1
%%% '''

-module(greperl).

%% escript callback
-export([main/1]).

%% API
-export([file_to_grepable/2]).
-export([terms_to_grepable/2]).

%% @private
main(Args) ->
    OptSpecList = get_opt_spec(),
    case getopt:parse(OptSpecList, Args) of
        {ok, {Opts, Extra}} ->
            case proplists:get_bool(help, Opts) of
                true ->
                    usage(OptSpecList);
                false ->
                    case Extra of
                        [Filename] -> main_to_grepable(Filename, Opts);
                        _          -> fail("missing argument", [])
                    end
            end;
        {error, {Reason, Data}} ->
            fail("~p -- ~p", [Reason, Data])
    end.

get_opt_spec() ->
    [{help,         $h,        "help",             undefined,
      "show help"},
     {separator,    $s,        "separator",        string,
      "set key-value separator"},
     {no_quote_str, undefined, "no-quote-strings", undefined,
      "do not quote strings"}].

usage(OptSpecList) ->
    getopt:usage(
      OptSpecList, "greperl", "<file>",
      [{"<file>", "name of file which can be read using file:consult/1"}]).

fail(Format, Args) ->
    io:format("greperl: "++Format++"~n", Args),
    halt(1).

main_to_grepable(Filename, Opts) ->
    case file_to_grepable(Filename, Opts) of
        {ok, IoList} ->
            io:format(IoList);
        {error, Reason} ->
            fail("~p", [Reason])
    end.

%% @doc Convert the terms inside the file into an io list with
%% something that can be grep:ed.
%% @see terms_to_grepable/2
-spec file_to_grepable(Filename, Opts) -> {ok, iolist()} | {error, term()}  when
      Filename :: file:filename_all(),
      Opts :: [Opt],
      Opt :: {separator, string()} | no_quote_str.
file_to_grepable(Filename, Opts) when is_list(Filename), is_list(Opts) ->
    case file:consult(Filename) of
        {ok, Terms} ->
            {ok, terms_to_grepable(Terms, Opts)};
        {error, _}=Error ->
            Error
    end.

%% @doc Convert the terms into an io list with something that can be grep:ed.
%%
%% <ul>
%%   <li>separator - set the string which separates the key from the value
%%       in the output (default: "=")</li>
%%   <li>no_quote_str - don't put quotes around values which are strings</li>
%% </ul>
-spec terms_to_grepable(Terms, Opts) -> iolist() when
      Terms :: [term()],
      Opts :: [Opt],
      Opt :: {separator, string()} | no_quote_str.
terms_to_grepable(Terms, Opts)  when is_list(Terms) ->
    to_grepable(Terms, _KPath=[], Opts).

to_grepable(Term, KPath, Opts) ->
    case is_leaf(Term) of
        true ->
            pp_kv_str(KPath, Term, Opts);
        false ->
            non_leaf_to_grepable(Term, KPath, Opts)
    end.

non_leaf_to_grepable([], _KPath, _Opts) ->
    [];
non_leaf_to_grepable([Term|Terms], KPath, Opts) ->
    [case Term of
         {K, V} ->
             to_grepable(V, [K|KPath], Opts);
         _ ->
             case is_leaf(Term) of
                 true  -> pp_kv_str(KPath, Term, Opts);
                 false -> non_leaf_to_grepable(Term, [""|KPath], Opts)
             end
     end | non_leaf_to_grepable(Terms, KPath, Opts)].

is_leaf(Term) when is_list(Term) ->
    io_lib:printable_list(Term);
is_leaf(_Term) ->
    true.

pp_kv_str(KPath, V, Opts) ->
    Sep = proplists:get_value(separator, Opts, "="),
    f("~s~s~s~n", [path_to_dotted_str(KPath), Sep, pp_val_str(V, Opts)]).

path_to_dotted_str(KPath0) ->
    KPath = [case io_lib:printable_list(K) of
                 true  -> K;
                 false -> f("~w", [K])
             end || K <- KPath0],
    string:join(lists:reverse(KPath), ".").

pp_val_str(V, Opts) ->
    NoQuoteStr = proplists:get_bool(no_quote_str, Opts),
    %% avoid line breaks, hope lines are not longer than 1024
    Str = f("~1024p", [V]),
    case NoQuoteStr of
        false -> Str;
        true  -> string:strip(Str, both, $")
    end.

f(Format, Args) ->
    lists:flatten(io_lib:format(Format, Args)).
