defmodule HashidsTest.Encode do
  use ExUnit.Case

  import HashidsTest.Helpers

  testcase_from_fixture "default_salt"
  testcase_from_fixture "default_salt_list"
  testcase_from_fixture "min_length_3"
  testcase_from_fixture "min_length_20"
  testcase_from_fixture "custom_salt_1"
  testcase_from_fixture "custom_salt_2"
  testcase_from_fixture "short_alphabet"
  testcase_from_fixture "custom_alphabet"
  testcase_from_fixture "long_alphabet"
  testcase_from_fixture "mix_and_match"

  testcase_from_fixture_large "default_salt_large"
  testcase_from_fixture_large "custom_salt_large"
  testcase_from_fixture_large "min_length_20_large"
  testcase_from_fixture_large "short_alphabet_large"
  testcase_from_fixture_large "long_alphabet_large"

  test "decode! fail throws exception" do
    assert_raise Hashids.DecodingError, fn->
      Hashids.decode!(Hashids.new,"%%%%%")
    end
  end
end
