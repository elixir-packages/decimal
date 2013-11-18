defmodule Decimal do
  import Kernel, except: [abs: 1]

  use Decimal.Record

  def abs(num) do
    dec(coef: coef) = d = to_decimal(num)
    dec(d, coef: Kernel.abs(coef))
  end

  def add(num1, num2) do
    dec(coef: coef1, exp: exp1) = to_decimal(num1)
    dec(coef: coef2, exp: exp2) = to_decimal(num2)

    { coef1, coef2 } = coef_align(coef1, exp1, coef2, exp2)
    coef = coef1 + coef2
    exp = min(exp1, exp2)
    dec(coef: coef, exp: exp)
  end

  def to_decimal(dec() = d), do: d
  def to_decimal(int) when is_integer(int), do: dec(coef: int)
  def to_decimal(float) when is_float(float), do: to_decimal(float_to_binary(float))
  def to_decimal(binary) when is_binary(binary), do: parse(binary)
  def to_decimal(_), do: raise ArgumentError

  ## ARITHMETIC ##

  defp coef_align(coef1, exp1, coef2, exp2) when exp1 == exp2 do
    { coef1, coef2 }
  end

  defp coef_align(coef1, exp1, coef2, exp2) when exp1 > exp2 do
    { coef1 * int_pow10(exp1 - exp2), coef2 }
  end

  defp coef_align(coef1, exp1, coef2, exp2) when exp1 < exp2 do
    { coef1, coef2 * int_pow10(exp2 - exp1) }
  end

  defp int_pow10(x) when x >= 0, do: int_pow10(x, 1)

  defp int_pow10(0, acc), do: acc
  defp int_pow10(x, acc), do: int_pow10(x-1, 10*acc)

  ## PARSING ##

  defp parse("NaN") do
    dec(coef: :NaN)
  end

  defp parse("+" <> bin) do
    parse_unsign(bin)
  end

  defp parse("-" <> bin) do
    dec(coef: coef) = d = parse_unsign(bin)
    dec(d, coef: -coef)
  end

  defp parse(bin) do
    parse_unsign(bin)
  end

  defp parse_unsign("inf") do
    dec(coef: :inf)
  end

  defp parse_unsign(bin) do
    { int, rest } = parse_digits(bin)
    { float, rest } = parse_float(rest)
    { exp, rest } = parse_exp(rest)

    if int == [] or rest != "", do: raise ArgumentError
    if exp == [], do: exp = '0'

    dec(coef: list_to_integer(int ++ float), exp: list_to_integer(exp) - length(float))
  end

  defp parse_float("." <> rest), do: parse_digits(rest)
  defp parse_float(bin), do: { [], bin }

  defp parse_exp(<< e, rest :: binary >>) when e in [?e, ?E] do
    case rest do
      << sign, rest :: binary >> when sign in [?+, ?-] ->
        { digits, rest } = parse_digits(rest)
        { [sign|digits], rest }
      _ ->
        parse_digits(rest)
    end
  end

  defp parse_exp(bin) do
    { [], bin }
  end

  defp parse_digits(bin), do: parse_digits(bin, [])

  defp parse_digits(<< digit, rest :: binary >>, acc) when digit in ?0..?9 do
    parse_digits(rest, [digit|acc])
  end

  defp parse_digits(rest, acc) do
    { :lists.reverse(acc), rest }
  end
end
