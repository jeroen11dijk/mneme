defmodule Mneme.Integration.BasicTest do
  use ExUnit.Case
  use Mneme

  alias Mneme.Versions

  @mneme action: :reject
  test "auto_assert/1 raises if no pattern is present and update is rejected" do
    assert_raise Mneme.AssertionError, "No pattern present", fn ->
      # ignore
      auto_assert :foo
    end
  end

  @mneme action: :reject
  test "auto_assert/1 raises if the match fails and update is rejected" do
    error =
      assert_raise ExUnit.AssertionError, fn ->
        # ignore
        auto_assert :foo <- :bar
      end

    assert %{left: :foo, right: :bar, message: "match (=) failed"} = error
  end

  test "integers" do
    # y
    auto_assert 4 <- 2 + 2

    # y
    auto_assert 4 <- 2 + 1, 3 <- 2 + 1
  end

  test "floats" do
    # y
    auto_assert 4.0 <- 2.0 + 2

    # y
    auto_assert 4.0 <- 2.0 + 1, 3.0 <- 2.0 + 1

    # y
    auto_assert +0.0 <- 1.0 * 0

    if Versions.match?(otp: ">= 27.0.0") do
      # ignore
      auto_assert -0.0 <- -1.0 * 0
    end
  end

  test "strings/binaries" do
    # y
    auto_assert "foobar" <- "foo" <> "bar"

    # y
    auto_assert "foobar" <- "foo" <> "baz", "foobaz" <- "foo" <> "baz"

    # y
    auto_assert <<0>> <- <<0>>

    # k y
    auto_assert """
                foo
                \\
                bar
                """ <- """
                foo
                \\
                bar
                """

    # y
    auto_assert "foo\rbar" <- "foo\rbar"

    # y
    auto_assert """
                foo
                bar
                """ <- """
                foo
                baz
                """,
                """
                foo
                baz
                """ <- """
                foo
                baz
                """
  end

  test "tuples" do
    # y
    auto_assert {1, 2, 3} <- {1, 2, 3}

    my_ref = make_ref()

    t = {1, my_ref}
    # y
    auto_assert ^t <- t
    # k y
    auto_assert {1, ^my_ref} <- t
    # k k y
    auto_assert {1, ref} when is_reference(ref) <- t

    t2 = {1, 2, my_ref}
    # y
    auto_assert ^t2 <- t2
    # k y
    auto_assert {1, 2, ^my_ref} <- t2
    # k k y
    auto_assert {1, 2, ref} when is_reference(ref) <- t2
  end

  test "lists" do
    # y
    auto_assert [1, 2, 3] <- [1, 2, 3]

    # y
    auto_assert [8, 9, 10] <- [8, 9, 10]

    my_ref = make_ref()
    l = [my_ref]
    # y
    auto_assert ^l <- l
    # k y
    auto_assert [^my_ref] <- l
    # k k y
    auto_assert [ref] when is_reference(ref) <- l
  end

  test "improper lists" do
    # y
    auto_assert [:x | :y] <- [:x | :y]
  end

  test "charlists" do
    # y
    auto_assert [102, 111, 111] <- String.to_charlist("foo")
    # k y
    auto_assert ~c"foo" <- String.to_charlist("foo")
  end

  describe "maps" do
    test "basic patterns" do
      # y
      auto_assert %{foo: 1} <- Map.put(%{}, :foo, 1)

      m = %{foo: 1}
      # y
      auto_assert ^m <- m
      # k y
      auto_assert %{foo: 1} <- m

      my_ref = make_ref()
      m = %{ref: my_ref}
      # y
      auto_assert ^m <- m
      # k y
      auto_assert %{ref: ^my_ref} <- m
      # k k y
      auto_assert %{ref: ref} when is_reference(ref) <- m
    end

    test "maps as map keys do not generate empty pattern" do
      m = %{%{foo: 1} => :bar}

      # y
      auto_assert ^m <- m
      # k y
      auto_assert %{%{foo: 1} => :bar} <- m
      # k k y
      auto_assert ^m <- m

      # k y
      auto_assert %{[%{foo: 1}] => :bar} <- %{[%{foo: 1}] => :bar}
    end
  end

  test "sigils" do
    # y
    auto_assert "foo" <- ~s(foo)

    # y
    auto_assert "foo" <- ~S(foo)

    # y
    auto_assert [102, 111, 111] <- ~c(foo)
    # k y
    auto_assert ~c"foo" <- ~c(foo)

    # y
    auto_assert [102, 111, 111] <- ~C(foo)
    # k y
    auto_assert ~c"foo" <- ~c(foo)
    # k y
    auto_assert ~c"foo" <- ~c"foo"
    # NOTE: Formatter bug in Elixir is causing this whitespace to collapse.
    # y
    auto_assert ~r/abc/ <- ~r/abc/
    # y
    auto_assert ~r/abc/mu <- ~r/abc/mu
    # y
    auto_assert ~r/a#\{b\}c/ <- ~r/a#\{b\}c/
  end

  test "falsy values" do
    # y
    auto_assert false <- false

    # y
    auto_assert nil <- nil

    falsy = false
    # y
    auto_assert false <- falsy
  end

  test "ranges" do
    # y
    auto_assert 1..10//_ <- Range.new(1, 10)
    # y
    auto_assert 1..10//2 <- Range.new(1, 10, 2)
  end
end
