%%
%%

-module(ebml_test).

-include_lib("eunit/include/eunit.hrl").

tokens_test() ->
    ?assertMatch({[], _}, ebml:tokens(<<>>)),
    ok.

token_test_webm_test() ->
    {ok, Data} = file:read_file("test/data/test.webm"),

    {Tokens, State} = ebml:tokens(Data),
    ?assertEqual(1212, length(Tokens)),

    %% Check if there is no leftover data.
    ?assertEqual(<<>>, ebml:data(State)), 

    %% Check if we parsed to the end of the file.
    ?assertEqual(219448, ebml:offset(State)), 
    ?assertEqual(219448, size(Data)), 

    ok.

