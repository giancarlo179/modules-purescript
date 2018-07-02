module Test.Main where

import Prelude
import Effect (Effect)
import Test.Spec (describe, it)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (run)
import Test.Spec.Assertions (shouldEqual)

import Math (pow)
import Data.List (fromFoldable)
import Data.Maybe (Maybe(..))

-- tested modules
import Calculator (UnparsedCharacterSet, calculate)
import NamedNumber (NamedNumber, namedNumber)
import Period (Period, Result, period)
import Checker (Results, Level(..), check)
import Utility (findLast)

import Checks.Dictionary as Dictionary
import Checks.Pattern as Pattern
import Checks.Patterns as Patterns

-- dictionaries
foreign import characterSets :: Array UnparsedCharacterSet
foreign import namedNumbers :: Array NamedNumber
foreign import periods :: Array Period
foreign import top10 :: Array String
foreign import top10k :: Array String
foreign import patterns :: Array Patterns.Pattern

check' :: String -> Results
check' = check (fromFoldable [
    Dictionary.check top10
  , Pattern.check "length.short" Warning "^.{7,9}$"
])

check10k :: String -> Results
check10k = check (fromFoldable [
    Dictionary.check top10k
])

patternsCheck :: String -> Results
patternsCheck = check (Patterns.patterns patterns)


-- helper functions
calculate' :: String -> Number
calculate' = calculate characterSets

namedNumber' :: Number -> String
namedNumber' = namedNumber namedNumbers

period' :: Number -> Number -> Maybe Result
period' = period periods

-- tests
main :: Effect Unit
main = run [consoleReporter] do
    describe "Utility (findLast)" do
        it "finds last item" do
           findLast (\x -> x > 5) Nothing (fromFoldable [1, 2, 3, 4, 9, 10]) `shouldEqual` Just 4
           findLast (\x -> x > 9) Nothing (fromFoldable [1, 2, 3, 4, 9, 10]) `shouldEqual` Just 9
           findLast (\x -> x > 10) Nothing (fromFoldable [1, 2, 3, 4, 9, 10]) `shouldEqual` Just 10

    describe "Checks (checks)" do
        it "checks" do
            check' "password" `shouldEqual` fromFoldable [{
                id: "common",
                level: Insecure,
                value: Just "1"
            }, {
                id: "length.short",
                level: Warning,
                value: Nothing
            }]
            check' "qwerty" `shouldEqual` fromFoldable [{
                id: "common",
                level: Insecure,
                value: Just "5"
            }]
            check10k "gocats" `shouldEqual` fromFoldable [{
                id: "common",
                level: Insecure,
                value: Just "9918"
            }]
            check' "abcd1234" `shouldEqual` fromFoldable [{
                id: "length.short",
                level: Warning,
                value: Nothing
            }]
            patternsCheck "abcd1234" `shouldEqual` fromFoldable [{
                id: "just.alphanumeric",
                level: Warning,
                value: Nothing
            }, {
                id: "length.short",
                level: Warning,
                value: Nothing
            }, {
                id: "no.symbols",
                level: Notice,
                value: Nothing
            }]
            patternsCheck "correcthorsebatterystaple" `shouldEqual` fromFoldable [{
                id: "xkcd",
                level: EasterEgg,
                value: Nothing
            }, {
                id: "just.letters",
                level: Notice,
                value: Nothing
            }, {
                id: "length.long",
                level: Achievement,
                value: Nothing
            }]

    describe "Calculator (calculate)" do
        it "calculates" do
            calculate' "i" `shouldEqual` 26.0
            calculate' "1" `shouldEqual` 10.0
            calculate' "hello" `shouldEqual` 11881376.0
            calculate' "abc123ABC" `shouldEqual` 13537086546263552.0

            calculate' "skdkfkdkfkekfkekfudkfieifidifieifieifiri" `shouldEqual` 3.971311183896361e56

    describe "NamedNumber (namedNumber)" do
        it "names numbers" do
            namedNumber' 1.0 `shouldEqual` "1"
            namedNumber' 0.0 `shouldEqual` "0"
            namedNumber' 12.0 `shouldEqual` "12"
            namedNumber' 220.0 `shouldEqual` "2 hundred"
            namedNumber' 3200.0 `shouldEqual` "3 thousand"
            namedNumber' 42000.0 `shouldEqual` "42 thousand"
            namedNumber' 520000.0 `shouldEqual` "5 hundred thousand"
            namedNumber' 6200000.0 `shouldEqual` "6 million"
            namedNumber' 72000000.0 `shouldEqual` "72 million"
            namedNumber' 820000000.0 `shouldEqual` "8 hundred million"
            namedNumber' 9200000000.0 `shouldEqual` "9 billion"
            namedNumber' 12000000000.0 `shouldEqual` "12 billion"
            namedNumber' 220000000000.0 `shouldEqual` "2 hundred billion"
            namedNumber' (200.0 * (10.0 `pow` 123.0)) `shouldEqual` "2 hundred quadragintillion"
            namedNumber' (2.0 * (10.0 `pow` 152.0)) `shouldEqual` "2 hundred octillion quadragintillion"
            namedNumber' (10.0 `pow` 308.0) `shouldEqual` "1 hundred uncentillion"
            namedNumber' (100.0 `pow` 308.0) `shouldEqual` "Infinity"

    describe "Period (periods)" do
        it "works out sub-yoctoseconds" do
            period' (10.0 `pow` 25.0) 1.0 `shouldEqual` Just { value: 0.0, name: "yoctoseconds" }

        it "works out yoctoseconds" do
            period' (10.0 `pow` 24.0) 1.0 `shouldEqual` Just { value: 1.0, name: "yoctosecond" }

        it "works out seconds" do
            period' 1.0 1.0 `shouldEqual` Just { value: 1.0, name: "second" }

        it "works out minutes" do
            period' 1.0 60.0 `shouldEqual` Just { value: 1.0, name: "minute" }

        it "works out hours" do
            period' 1.0 3600.0 `shouldEqual` Just { value: 1.0, name: "hour" }

        it "works out years" do
            period' 0.01 315576.0 `shouldEqual` Just { value: 1.0, name: "year" }

        it "works out multiple yoctoseconds" do
            period' (10.0 `pow` 24.0) 7.0 `shouldEqual` Just { value: 7.0, name: "yoctoseconds" }

        it "works out multiple seconds" do
            period' 0.5 1.0 `shouldEqual` Just { value: 2.0, name: "seconds" }

        it "works out multiple minutes" do
            period' 0.5 60.0 `shouldEqual` Just { value: 2.0, name: "minutes" }

        it "works out multiple hours" do
            period' 0.5 3600.0 `shouldEqual` Just { value: 2.0, name: "hours" }

        it "works out multiple years" do
            period' 0.005 315576.0 `shouldEqual` Just { value: 2.0, name: "years" }
