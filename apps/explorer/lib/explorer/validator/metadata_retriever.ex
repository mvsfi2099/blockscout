defmodule Explorer.Validator.MetadataRetriever do
  @moduledoc """
  Consults the configured smart contracts to fetch the valivators' metadata
  """

  alias Explorer.SmartContract.Reader

  def fetch_data do
    fetch_validators_list()
    |> Enum.map(fn validator ->
      validator
      |> fetch_validator_metadata
      |> translate_metadata
      |> Map.merge(%{address_hash: validator, primary: true})
    end)
  end

  defp fetch_validators_list do
    # b7ab4db5 = keccak256(getValidators())
    case Reader.query_contract(config(:poseidon_contract_address), contract_abi("poseidon.json"), %{
           "b7ab4db5" => []
         }) do
      %{"b7ab4db5" => {:ok, [validators]}} -> validators
      _ -> []
    end
  end

  defp fetch_validator_metadata(validator_address) do
    # 8a11d7c9 = keccak256(getValidatorInfo(address))
    %{"8a11d7c9" => {:ok, fields}} =
      Reader.query_contract(config(:poseidon_contract_address), contract_abi("poseidon.json"), %{
        "8a11d7c9" => [validator_address]
      })

    fields
  end

  defp translate_metadata([
         name,
         reward_addr,
         _total_supply,
         _last_block_height,
       ]) do
    %{
      name: trim_null_bytes(name),
      reward: reward_addr,
      metadata: %{}
    }
  end

  defp trim_null_bytes(bytes) do
    String.trim_trailing(bytes, <<0>>)
  end

  defp config(key) do
    Application.get_env(:explorer, __MODULE__, [])[key]
  end

  # sobelow_skip ["Traversal"]
  defp contract_abi(file_name) do
    :explorer
    |> Application.app_dir("priv/contracts_abi/poa/#{file_name}")
    |> File.read!()
    |> Jason.decode!()
  end
end
