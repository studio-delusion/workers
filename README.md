# workers

workers is a Roblox library for code parallization through the use of Actors.

# Usage

> [!NOTE]
> In Luau, threads are coroutines. Coroutines are executed serially by a single CPU core, as opposed to "real" threads, which have the ability to run on different CPU cores.\
> Therefore, any references to threads are references to "real" threads.

> [!CAUTION]
> Be smart about what you parallelize. More ofter than not it'll lead to worse results than doing it normally.\
> If you think something is gonna benefit from splitting it across threads, first benchmark it.\
> Read [this article by Roblox](https://create.roblox.com/docs/scripting/multithreading) before parallelizing your code.

## Workers

In order to create a worker, you first need to create a ModuleScript which will house the code you wish to run multithreaded.
```lua
-- hello.luau
local Hello = {}

-- Workers call "run" on ModuleScripts
function Hello.run()
    print("Hello from another thread!")
end

return Hello
```

Afterwards, it's as simple as creating a worker with the ModuleScript!
```lua
local Workers = require(path.to.workers)
local hello = path.to.hello

local worker = Workers.worker(hello)
```

Now, you can run the ModuleScript on another thread:
```lua
worker:run()
```

You can optionally pass values to workers:
```lua
-- hello.luau
local Hello = {}

-- Workers call "run" on ModuleScripts
function Hello.run(message: string)
    print(`Hello from another thread! My caller says "{message}"`)
end

return Hello
```

```lua
worker:run("Hello from caller!")
```

You can return values from `.run()`...
```lua
-- add.luau
local Add = {}

-- Workers call "run" on ModuleScripts
function Add.run(a: number, b: number): number
    return a + b
end

return Add
```

...and get them by joining the thread back to serial execution!
```lua
worker:run(2, 2)
local ok, result = worker:join()
```

> [!WARNING]
> `worker:join()` will yield until the worker finishes running.\
> You can prevent this by disallowing the worker from attempting to join more than once:
> ```lua
> local ok, result = worker:join(1)
> ```
> or by giving it a certain amount of attempts it can perform before failing:
> ```lua
> local ok, result = worker:join(5)
> ```

## Pools

Pools work roughly the same as workers, except with a few extra features.

You create a ModuleScript
```lua
-- add.luau
local Add = {}
Add.Index = 0 -- The index of the worker in the pool, the worker will automatically set the `Index` behind the curtains, therefore you can make it any number you want in the module

function Add.run(a: number, b: number): number
    return a + b
end

return Add
```

Bind it to a pool
```lua
local pool = Workers.pool(10, add) -- Creates a pool bound to the ModuleScript `add` with 10 workers
```

Run the pool
```lua
pool:run(2, 2)
```

And get return values from the pool
```lua
local ok = pool:join()
if not ok then return end

local ok, result = pool:get_result(1)
```
You might have noticed that we joined the pool and called another function with a number.\
This is because in the case of pools, `join()` joins all workers back into serial execution **without** returning the results.\
Therefore we fetch the results with `get_results()` and the index of the worker whose results we want.

Though, do note that you can simply join the nth worker from the pool you want, and instantly get it's result.
```lua
local ok, result = pool:join_nth(1)
```

## Cleaning up

You can clean up workers and pools by calling `:destroy()` on them.
```lua
worker:destroy()
pool:destroy()
```
