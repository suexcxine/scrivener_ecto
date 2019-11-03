defimpl Scrivener.Paginater, for: Ecto.Query do
  import Ecto.Query

  alias Scrivener.{Config, Page}

  @moduledoc false

  @spec paginate(Ecto.Query.t(), Scrivener.Config.t()) :: Scrivener.Page.t()
  def paginate(query, %Config{
        page_size: page_size,
        page_number: page_number,
        module: repo,
        caller: caller,
        options: options
      }) do
    entries = entries(query, repo, page_number, page_size, caller, options)
    total_entries =
      Keyword.get_lazy(options, :total_entries, fn -> total_entries(page_number, page_size, Enum.count(entries)) end)
    total_pages = total_pages(total_entries, page_size)
    %Page{
      page_size: page_size,
      page_number: page_number,
      entries: entries,
      total_entries: total_entries,
      total_pages: total_pages
    }
  end

  defp entries(query, repo, page_number, page_size, caller, options) do
    offset = Keyword.get_lazy(options, :offset, fn -> page_size * (page_number - 1) end)

    query
    |> offset(^offset)
    |> limit(^page_size)
    |> repo.all(caller: caller)
  end

  defp total_entries(page_number, page_size, entries_count) when entries_count >= page_size do
    (page_number - 1) * page_size + entries_count + 1
  end
  defp total_entries(page_number, page_size, entries_count) do
    (page_number - 1) * page_size + entries_count
  end

  defp total_pages(0, _), do: 1

  defp total_pages(total_entries, page_size) do
    (total_entries / page_size) |> Float.ceil() |> round
  end
end

