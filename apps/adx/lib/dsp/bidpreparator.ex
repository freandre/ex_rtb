defmodule Dsp.BidPreparator do
  def filter_and_format(response_lst, request) when is_list(response_lst) do
    response_lst
    |> Stream.filter(&(&1 != :nothing))
    |> Stream.map(&Poison.decode!/1)
    |> Stream.filter(&Dsp.Validator.validate(&1, request))
    |> Stream.map(&Dsp.Normalizer.normalize_price(&1, "USD"))
  end

  def flatten_and_split(response_lst) do
    {individually, bygroup} =
      response_lst
      |> Stream.transform(0, &{Map.get(&1, "seatbid"), &2})
      |> Enum.split_with(&(Map.get(&1, "group") == 0))

    {index_bids(individually), bygroup}
  end

  defp index_bids(seatbids) do
    seatbids
    |> Enum.reduce(%{}, &map_by_impid(Map.get(&1, "bid"), &2))
  end

  defp map_by_impid(bids, map) do
    bids
    |> Enum.reduce(map, fn bid, acc ->
      impid = bid["impid"]

      Map.get_and_update(acc, impid, fn value ->
        case value do
          nil -> [bid]
          list -> [bid | list]
        end
      end)
    end)
  end
end
