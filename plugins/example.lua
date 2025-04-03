function Commands.print_to_stdout(text)
    print(text)
end

--[[
AddEventHandler('hydrus:insert', function(table, data, ctx)
    if table == 'vrp_user_vehicles' then
        ctx.defer()
        ctx.merge({ custom_column = 1 })
        ctx.done()
    end
end)
]]