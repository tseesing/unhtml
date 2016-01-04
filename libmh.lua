
require ("html")

libmh = {}

-- 将表中的文本部分(非标签及其属性)串接
-- 也是深度优先. 留意文本串接顺序
function libmh.concatText(tagTable)
    if type(tagTable) ~= "table" then return tostring(tagTable) end
    local s1 = ""
    for _, v in ipairs(tagTable) do
        if type(v) == "string" then 
            s1 = s1 .. v
        elseif type(v) == "table" then
            --[[ -- 要不要ST文本?( ST文本就是 <! > 标签间的文本)
            if v._st then
              s1 = s1 .. v._stText
            --]]
            if not v._st and v._tag ~= "script" and
                v._tag ~= "SCRIPT"
            then
              s1 = s1 .. libmh.concatText(v)
            end
        end
    end
    return s1
end

-- 转义(实现参考 html.lua 的 unescape())
libmh.html_escape = {
  [" "] = "&nbsp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ["\""] = "&quot;",
  ["&"] = "&amp;"
}
setmetatable(libmh.html_escape, { __index = function(t, k) return k end})

function libmh.tagTable2html_real(tagTable)
    local htmlstr = ""
    if tagTable._st then 
        htmlstr = htmlstr .. tagTable._stText 
    else
        htmlstr = htmlstr .."<" .. tagTable._tag
        for attrn, attrv in pairs(tagTable._attr) do
            -- print("attr name: ", attrn)
            local lattrv 
            if attrn == "src" or attrn == "href" then
              lattrv = string.gsub(attrv, '[ <>"&]', libmh.html_escape)
            else
              lattrv = string.gsub(attrv, '[<>"&]', libmh.html_escape)
            end
            htmlstr = htmlstr  .. " " .. attrn .. "=" ..'"'.. lattrv .. '"'
        end
        if html.tags[tagTable._tag].empty then -- tags definitioned within html.lua
            htmlstr = htmlstr .. " />"    -- <br /> 
        else
            htmlstr = htmlstr .. ">" 
        end        
    end
    for _, v in ipairs(tagTable) do -- 用 ipairs() 遍历, 跳过 _tag, _attr
        if type(v) == "table" then
            htmlstr = htmlstr ..libmh.tagTable2html_real(v)
        elseif type(v) == "string" then
            htmlstr = htmlstr .. string.gsub(v, '[<>"&]', libmh.html_escape)
        end
    end
    if tagTable._tag 
        and tagTable._tag ~= "#document"
        and not html.tags[tagTable._tag].empty -- tags definitioned within html.lua
    then
        htmlstr = htmlstr .. "</" .. tagTable._tag .. ">"
    end        
    return htmlstr
end
--[[ !!
html.lua 中, 将(如果有的话) <!DOCTYPE ...> 解释成 ._tag =  nil
还有注释行也是如此
--]]
function libmh.tagTable2html(tagTable)
    if type(tagTable) ~= "table" then return tostring(tagTable) end
    return libmh.tagTable2html_real(tagTable)
end


