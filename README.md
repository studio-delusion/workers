# workers

workers is a Roblox library for code parallization through the use of Actors.

# Usage

> [!INFO]
> In Luau, threads are coroutines. Coroutines are executed serially by a single CPU core, as opposed to "real" threads, which have the ability to run on different CPU cores.
> "Workers" in this module refer to "real" threads.

> [!CAUTION]
> Be smart about what you parallelize. More ofter than not it'll lead to worse results than doing it normally.
> If you think something is gonna benefit from splitting it across threads, first benchmark it.
