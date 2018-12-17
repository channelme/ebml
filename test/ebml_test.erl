%%
%%
%%

-module(ebml_test).

-include_lib("eunit/include/eunit.hrl").

tokens_test() ->
    ebml:tokens(<<>>),
    ok.
