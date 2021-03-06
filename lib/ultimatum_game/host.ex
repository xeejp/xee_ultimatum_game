defmodule UltimatumGame.Host do
  alias UltimatumGame.Main
  alias UltimatumGame.Actions

  def filter_data(data) do
    data
  end

  # Actions
  def visit(data) do
    Map.put(data, :is_first_visit, false)
  end

  def reset(data) do
    %{data |
      participants: data.participants
                    |> Enum.map(fn({id, state}) ->
                      {id, %{
                        role: "visitor",
                        point: 0,
                        pair_id: nil,
                      }}
                    end)
                    |> Enum.into(%{}),
      pairs: %{},
      ultimatum_results: %{},
      game_round: 1,
      game_redo: 0,
      inf_redo: false,
    }
  end

  def change_description(data, dynamic_text) do
    %{data | dynamic_text: dynamic_text}
  end

  def change_page(data, page) do
    if page in Main.pages do
      %{data | page: page}
    else
      data
    end
  end

  def change_game_round(data, game_round) do
    if game_round < 0 do game_round = 1 end
    %{data | game_round: game_round}
  end

  def change_inf_redo(data, inf_redo) do
    %{data | inf_redo: inf_redo }
  end

  def change_game_redo(data, game_redo) do
    if game_redo < -1 do game_redo = 0 end
    %{data | game_redo: game_redo }
  end

  def match(data) do
    %{participants: participants} = data
    participants = participants
                    |> Enum.map(fn({id, state}) ->
                      {id, %{
                        role: "visitor",
                        point: 0,
                        pair_id: nil,
                      }}
                    end)
                    |> Enum.into(%{})
    group_size = 2
    groups = participants
              |> Enum.map(&elem(&1, 0)) # [id...]
              |> Enum.shuffle
              |> Enum.chunk(group_size)
              |> Enum.map_reduce(1, fn(p, acc) -> {{Integer.to_string(acc), p}, acc + 1} end) |> elem(0) # [{0, p0}, ..., {n-1, pn-1}]
              |> Enum.into(%{})

    updater = fn participant, pair_id, role ->
      %{ participant |
        role: role,
        point: 0,
        pair_id: pair_id
      }
    end
    reducer = fn {group, ids}, {participants, pairs} ->
      [id1, id2] = ids
      participants = participants
                      |> Map.update!(id1, &updater.(&1, group, "proposer"))
                      |> Map.update!(id2, &updater.(&1, group, "responder"))

      pairs = Map.put(pairs, group, Main.new_pair(ids))
      {participants, pairs}
    end
    acc = {participants, %{}}
    {participants, groups} = Enum.reduce(groups, acc, reducer)

    %{data | participants: participants, pairs: groups}
  end
end
