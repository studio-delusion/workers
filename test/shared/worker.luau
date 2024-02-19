local Worker = {}
Worker.Index = 0

function Worker.run(message: string)
	print(`{Worker.Index}: {message}`)
end

return Worker
