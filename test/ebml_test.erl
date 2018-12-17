%%
%%
%%

-module(ebml_test).

-include_lib("eunit/include/eunit.hrl").

tokens_test() ->
    ?assertMatch({[], _}, ebml:tokens(<<>>)),
    ok.
