defmodule Bench.HashidsDecode do
  use Benchfella

  hashids = [
    {"long alphabet", Hashids.new(
      alphabet: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" <>
                "~!@#$%^&*()_+\"][{}|;:/?.>,<あいうえおかきくけこさしすせそたちつ" <>
                "てとまみむめもらちるれろはひふへほやゆよんをわなにぬねの" <>
                "абвгдежзийклмнопрстуфхцчшщьыъэюяАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
    )},
    {"default alphabet", Hashids.new()}
  ]

  for {alpha, h} <- hashids do
    @h h
    bench "#{alpha}: decode 1 integer", input: encode(@h, 100) do
      Hashids.decode(@h, input)
    end

    bench "#{alpha}: decode 10 integers", input: encode(@h, 1000..1010 |> Enum.to_list) do
      Hashids.decode(@h, input)
    end

    bench "#{alpha}: decode 100 integers", input: encode(@h, 100..200 |> Enum.to_list) do
      Hashids.decode(@h, input)
    end
  end

  defp encode(h, nums) do
    Hashids.encode(h, nums)
  end
end
