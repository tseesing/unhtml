
mhfilter = {}
--
-- 深度优先
-- myArgs must be: {{attrname, attrvalue}, ...}
-- return type is Table
function mhfilter.getTagTable(html_table, tagname, myArgs) 
    if  type(html_table) ~= "table"  or 
        type(tagname)    ~= "string"
    then
        coroutine.yield(nil)
    end
    if html_table._tag == tagname then
        local allAttrMatched = true 
        for attrk, attrv in ipairs(myArgs) do
            allAttrMatched = allAttrMatched and (html_table._attr[attrv[1]] == attrv[2])  
            if not allAttrMatched then
                break
            end
        end
        if allAttrMatched then
            coroutine.yield(html_table)
        end 
    end
    for k, v in pairs(html_table) do
        if type(v) == "table" then
          mhfilter.getTagTable(v, tagname, myArgs) 
        end
    end
end
--
-- 深度优先
-- 与 mhfilter.getTagAllTable() 不同的地方是, 不会记录上次的遍历的位置
-- args {...} must be: {attrname, attrvalue [, RE]}
    -- RE 为 true 时, 属性的值使用规则表达式匹配
    --  
function mhfilter.findSpecifiedTag(tagTable, tag, ...)
    if not tagTable then return end
    if tagTable._tag == tag then
        -- 标签不需带任何属性的, 可返回了
        if tag == nil and #tagTable._attr == 0 then return tagTable end 
        local allAttrMatched = true 
        for attrk, attrv in ipairs({...}) do
            if attrv[3] ~= true then -- RE 式可部分匹配字符串
              allAttrMatched = allAttrMatched and (tagTable._attr[attrv[1]] == attrv[2])
            else
              allAttrMatched = allAttrMatched and tagTable._attr[attrv[1]] -- 确保有该标签属性
                    and string.match(tagTable._attr[attrv[1]], attrv[2])
            end
            if not allAttrMatched then
                break
            end
        end
        if allAttrMatched then
            return tagTable
        end        
    end
    for k, v in ipairs(tagTable) do
        if type(v) == "table" then
            thatisit = mhfilter.findSpecifiedTag (v, tag, ...) 
            if thatisit then return thatisit end
        end
    end
end


-- return type is Table
function mhfilter.getTagAllTable(html_table, tagname, ...)
    local myArgs = {...}
    local co = coroutine.create(function() 
              return mhfilter.getTagTable(html_table, tagname, myArgs)
            end)

    return  function()
      local code, tagTable = coroutine.resume(co)
      return tagTable
    end
end

