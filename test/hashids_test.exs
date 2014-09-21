defmodule HashidsTest.Encode do
  use ExUnit.Case

  import HashidsTest.Helpers

  test "default key" do
    s = Hashids.new()
    for {num, cipher} <- tests_from_fixture("default_key") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "default key multinum" do
    s = Hashids.new()
    for {numlist, cipher} <- tests_from_fixture("default_key_list") do
      assert cipher == Hashids.encode(s, numlist)
      assert numlist === Hashids.decode(s, cipher)
    end
  end

  test "default key large" do
    s = Hashids.new()
    for {num, cipher} <- tests_from_fixture_large("default_key_large") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "short alphabet" do
    s = Hashids.new(alphabet: 'abc1029384756XYZ')
    for {num, cipher} <- tests_from_fixture("short_alphabet") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "short alphabet large" do
    s = Hashids.new(alphabet: 'abc1029384756XYZ')
    for {num, cipher} <- tests_from_fixture_large("short_alphabet_large") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  @long_one 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~!@#$%^&*()_+"\][{}|;:/?.>,<あいうえおかきくけこさしすせそたちつてとまみむめもらちるれろはひふへほやゆよんをわなにぬねのабвгдежзийклмнопрстуфхцчшщьыъэюяАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ'

  test "long alphabet" do
    s = Hashids.new(alphabet: @long_one)
    for {num, cipher} <- tests_from_fixture("long_alphabet") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "long alphabet large" do
    s = Hashids.new(alphabet: @long_one)
    for {num, cipher} <- tests_from_fixture_large("long_alphabet_large") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end


  test "min length 3" do
    s = Hashids.new(min_len: 3)
    for {num, cipher} <- tests_from_fixture("min_length_3") do
      assert cipher == Hashids.encode(s, num)
      assert length(cipher) >= 3
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "min length 20" do
    s = Hashids.new(min_len: 20)
    for {num, cipher} <- tests_from_fixture("min_length_20") do
      assert cipher == Hashids.encode(s, num)
      assert length(cipher) == 20
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "min length 20 large" do
    s = Hashids.new(min_len: 20, alphabet: 'abcdefghijklmnop0')
    for {num, cipher} <- tests_from_fixture_large("min_length_20_large") do
      assert cipher == Hashids.encode(s, num)
      assert length(cipher) > 20
      assert [num] == Hashids.decode(s, cipher)
    end
  end

  test "custom key 1" do
    s = Hashids.new(key: 'hello world')
    for {num, cipher} <- tests_from_fixture("custom_key_1") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "custom key 2" do
    s = Hashids.new(key: '123_-+EBNFarigatou')
    for {num, cipher} <- tests_from_fixture("custom_key_2") do
      assert cipher == Hashids.encode(s, num)
      assert [num] === Hashids.decode(s, cipher)
    end
  end

  test "custom key large" do
    s = Hashids.new(key: '-->secret key, no salt<--')
    for {num, cipher} <- tests_from_fixture_large("custom_key_large") do
      assert cipher == Hashids.encode(s, num)
      assert [num] == Hashids.decode(s, cipher)
    end
  end

  test "mix and match" do
    s = Hashids.new(key: '123,./~_+', min_len: 5, alphabet: 'Aünîcø∂émädñèsSß')
    for {nums, cipher} <- tests_from_fixture("mix_and_match") do
      assert cipher == Hashids.encode(s, nums)
      assert List.wrap(nums) === Hashids.decode(s, cipher)
    end
  end
end
