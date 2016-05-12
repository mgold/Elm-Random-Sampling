module Random.Array exposing (sample, choose, shuffle)

{-|

# Random Sampling of Arrays

These implementations are thought to be correct as validated by non-rigorous
tests, and should be fine for games and simulations. Please do not trust them
when statisical or especially cryptographic randomness is required.

For best results, invoke `Random.initialSeed` only once in your program, and
thread the returned new seeds through. For a good random seed, evaluate
`Math.floor(Math.random()*0xFFFFFFFF)` either once and hard-code the result, or
as the value of `port initialSeed : Int`.


@docs sample, choose, shuffle

-}

import Random
import Array
import Dict
import Trampoline as T

{-| Sample with replacement: produce a randomly selected element of the
array and the new seed. Takes O(1) time. -}
sample : Random.Seed -> Array.Array a -> (Maybe a, Random.Seed)
sample seed arr =
    let intGen = Random.int 0 (Array.length arr - 1)
        (index, seed') = Random.generate intGen seed
    in (Array.get index arr, seed')

{-| Sample without replacement: produce a randomly selected element of the
array, the new seed, and the array with that element omitted (shifting all later
elements down). -}
choose : Random.Seed -> Array.Array a -> (Maybe a, Random.Seed, Array.Array a)
choose seed arr = if Array.isEmpty arr then (Nothing, seed, arr) else
    let lastIndex = Array.length arr - 1
        intGen = Random.int 0 lastIndex
        (index, seed') = Random.generate intGen seed
        front = Array.slice 0 index arr
        back = if index == lastIndex -- workaround for #1
               then Array.empty
               else Array.slice (index+1) (Array.length arr) arr
    in (Array.get index arr, seed', Array.append front back)

-- not exported
type alias ShuffleState a = (Random.Seed, List a, Array.Array a)

{-| Shuffle the array using the Fisher-Yates algorithm. Takes O(_n_ log _n_)
time and O(_n_) additional space. -}
shuffle : Random.Seed -> Array.Array a -> (Array.Array a, Random.Seed)
shuffle seed arr = if Array.isEmpty arr then (arr, seed) else
    let helper : ShuffleState a -> T.Trampoline (ShuffleState a)
        helper (s, xs, a) = let (m_val, s', a') = choose s a
            in case m_val of
                Nothing -> T.Done (s, xs, a)
                Just val -> T.Continue (\() -> helper (s', val::xs, a'))
        (seed', shuffled, _) = T.trampoline (helper (seed, [], arr))
    in (Array.fromList shuffled, seed')
