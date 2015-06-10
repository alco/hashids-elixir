defmodule Bench.HashidsEncode do
  use Benchfella

  @h_long Hashids.new(
    alphabet: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" <>
              "~!@#$%^&*()_+\"][{}|;:/?.>,<あいうえおかきくけこさしすせそたちつ" <>
              "てとまみむめもらちるれろはひふへほやゆよんをわなにぬねの" <>
              "абвгдежзийклмнопрстуфхцчшщьыъэюяАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
  )

  @h_def Hashids.new()

  bench "long alphabet: encode 1" do
    Hashids.encode(@h_long, 1)
  end

  bench "long alphabet: encode 100" do
    Hashids.encode(@h_long, 100)
  end

  bench "long alphabet: encode 10000" do
    Hashids.encode(@h_long, 10000)
  end

  bench "long alphabet: encode a list of 10 integers" do
    Hashids.encode(@h_long, Enum.to_list(1000..1010))
  end

  bench "default alphabet: encode 1" do
    Hashids.encode(@h_def, 1)
  end

  bench "default alphabet: encode 100" do
    Hashids.encode(@h_def, 100)
  end

  bench "default alphabet: encode 10000" do
    Hashids.encode(@h_def, 10000)
  end

  bench "default alphabet: encode a list of 10 integers" do
    Hashids.encode(@h_def, Enum.to_list(1000..1010))
  end
end
