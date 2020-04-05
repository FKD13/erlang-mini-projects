-module(bf).
-export([interpret/1]).

interpret([], _, _) -> ok;
interpret([62|Tokens], L1, []) -> interpret(Tokens, [0|L1], []);
interpret([62|Tokens], L1, [L|L2])  -> interpret(Tokens, [L|L1], L2);
interpret([60|Tokens], [A|[]], L2)  -> interpret(Tokens, [0], [A|L2]);
interpret([60|Tokens], [L|L1], L2)  -> interpret(Tokens, L1, [L|L2]);
interpret([46|Tokens], [L|L1], L2)  ->
  io:format("~s",[[L]]),
  interpret(Tokens, [L|L1], L2);
interpret([44|Tokens], [L1], L2)    ->
  [Char] = unicode:characters_to_list(io:get_chars("", 1)),
  interpret(Tokens, [Char|L1], L2);
interpret([43|Tokens], [L], L2)     -> interpret(Tokens, [(L+1) rem 255], L2);
interpret([43|Tokens], [L|L1], L2)  -> interpret(Tokens, [(L+1) rem 255|L1], L2);
interpret([45|Tokens], [L], L2)     -> interpret(Tokens, [(L-1) rem 255], L2);
interpret([45|Tokens], [L|L1], L2)  -> interpret(Tokens, [(L-1) rem 255|L1], L2);
interpret([91|Tokens], L1, L2) ->
  case interpret(Tokens, L1, L2) of
    {end_loop, NT, NL1, NL2} ->
      case hd(NL1) of
        0 -> interpret(NT, NL1, NL2);
        _ -> interpret([91|Tokens], NL1, NL2)
      end;
    ok -> throw(unexpected_ok)
  end;
interpret([93|T], L1, L2) -> {end_loop, T, L1, L2}.

interpret(L) -> interpret(L, [0], []).
