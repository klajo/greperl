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
-module(greperl_tests).

-include_lib("eunit/include/eunit.hrl").

-compile(export_all).

leaf_terms_test() ->
    "a=1\n"       = to_g([{a, 1}]),
    "b=x\n"       = to_g([{b, x}]),
    "c=\"foo\"\n" = to_g([{c, "foo"}]),
    "d=[]\n"      = to_g([{d, []}]),
    ok.
    
kv_pairs_test() ->
    ("a.x=1\n"
     "a.y=2\n"
     "b.z=3\n") = to_g([{a, [{x, 1}, {y, 2}]},
                        {b, [{z, 3}]}]),
    ("b.z=3\n"
     "b.w.c=4\n"
     "b.w.d=5\n") = to_g([{b, [{z, 3}, {w, [{c, 4}, {d, 5}]}]}]),
    ok.

list_of_non_kv_pairs_test() ->
    ("a=1\n"
     "a=2\n"
     "a=3\n") = to_g([{a, [1, 2, 3]}]),
    ("a=x\n"
     "a=y\n"
     "a=z\n") = to_g([{a, [x, y, z]}]),
    ok.

list_of_differently_sized_tuples_test() ->
    ("a=x\n"
     "a.x=1\n"
     "a={x,y,2}\n"
     "a.x=3\n") = to_g([{a, [x, {x, 1}, {x, y, 2}, {x, 3}]}]),
    ok.

lists_with_lists_test() -> 
    ("a..x=1\n"
     "a..x=2\n") = to_g([{a, [[{x, 1}], [{x, 2}]]}]),
    ok.

configure_separator_test() ->
    "a=1\n"   = to_g([{a, 1}]),
    "a-->1\n" = to_g([{a, 1}], [{separator, "-->"}]),
    ok.

dont_quote_strings_test() ->
    "a=\"foo\"\n" = to_g([{a, "foo"}]),
    "a=foo\n"     = to_g([{a, "foo"}], [no_quote_str]),
    ok.

to_g(Terms) ->
    to_g(Terms, []).

to_g(Terms, Opts) ->
    lists:flatten(greperl:terms_to_grepable(Terms, Opts)).
