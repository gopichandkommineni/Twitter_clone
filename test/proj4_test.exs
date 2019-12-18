defmodule Proj4Test do
  use ExUnit.Case, async: false
  doctest Proj4
  use GenServer

  setup_all do
    Proj4.create(500,1)
  end

  test "register user" do
    IO.inspect "test1"
    assert Proj4.register(13)
  end

  test "register existing again" do
    IO.inspect "test2"
    assert Proj4.register(13)
  end

  test "Subscribe user" do
    IO.inspect "test3"
    assert Proj4.subscribe(7,1)
  end  

  test "delete user" do
    IO.inspect "test4"
    assert Proj4.delete_account(6)
  end

  test "Subscribe user failure case" do
    IO.inspect "test5"
    assert Proj4.subscribe(7,6)
  end

  test "Subscribing same user" do
    IO.inspect "test6"
    assert Proj4.subscribe(7,7)
  end

  test "delete non-exisiting user" do
    IO.inspect "test7"
    assert Proj4.delete_account(6)
  end

  test "retweet" do
    IO.inspect "test8"
    assert Proj4.retweet(15) 
  end

  test "retweeting from deleted account" do
    IO.inspect "test9"
    assert Proj4.retweet(6) 
  end

   test "hash_query" do
    IO.inspect "test10"
    assert Proj4.hash_query("#Iamuser3")
  end

  test "hash_query incorrect format" do
    IO.inspect "test11"
    assert Proj4.hash_query("#Iam3")
  end

  test "hash_query non-existent" do
    IO.inspect "test12"
    assert Proj4.hash_query("#Iamuser003")
  end

  test "mention_query" do
    IO.inspect "test13"
    assert Proj4.mention_query("@3")
  end
 
  test "mention_query incorrect format" do
    IO.inspect "test14"
    assert Proj4.mention_query("@@")
  end
 
  test "mention_query non-existing user" do
    IO.inspect "test15"
    assert Proj4.mention_query("@6")
  end

end
