-- 用合约来完成一个提现系统
local L0 = require("L0")
-- 提现合约
local CName = "withdraw" 
local string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end
-- 合约创建时会被调用一次，之后就不会被调用
-- 设置系统账户地址 & 手续费账户地址
function L0Init(args)
    -- info
    local str = ""
    for k, v in ipairs(args) do 
        str = str .. v .. ","
    end
    print("INFO:" .. CName .. " L0Init(" .. string.sub(str, 0, -2) .. ")")

    -- validate
    if(#args ~= 2)
    then
        print("ERR :" .. CName ..  " L0Init --- wrong args number")
        return false
    end
    
    -- execute
    L0.PutState("version", 0)
    print("INFO:" .. CName ..  " L0Init --- system account " .. args[0])
    L0.PutState("account_system", args[0])
    print("INFO:" .. CName ..  " L0Init --- fee account " .. args[1])
    L0.PutState("account_fee", args[1])
    return true
end

-- 每次合约执行都调用
-- 发起提现 launch & 撤销提现 cacel & 提现成功 succeed & 提现失败 failed
function L0Invoke(func, args)
    -- info
    local str = ""
    for k, v in ipairs(args) do 
        str = str .. v .. ","
    end
    print("INFO:" .. CName ..  " L0Invoke(" .. func .. "," .. string.sub(str, 0, -2) .. ")")

    -- execute
    if("launch" == func) then
        return launch(args)
    elseif("cacel" == func) then
        return cacel(args)
    elseif("succeed" == func) then
        return succeed(args)
    elseif("fail" == func) then
        return fail(args)
    else
        print("ERR :" .. CName ..  " L0Invoke --- function not support")
        return false
    end
    return true
end

-- 查询
function L0Query(args)
    -- print info
    local str = ""
    for k, v in ipairs(args) do 
        str = str .. v .. ","
    end
    print("INFO:" .. CName ..  " L0Query(" .. string.sub(str, 0, -2) .. ")")

    local withdrawID = "launch_"..args[0]
    local withdrawInfo = L0.GetState(withdrawID)
    if (not withdrawInfo)
    then
        return "not found " .. withdrawID 
    end
    return withdrawInfo
end

--  发起提现, 发送方转账到合约账户，保存提现ID
--  参数：提现ID
--  前置条件: 提现ID不存在
function launch(args) 
    -- validate
    if(#args ~= 1)
    then
        print("ERR :" .. CName ..  " launch --- wrong args number")
        return false
    end

    -- execute 
    local withdrawID = "launch_"..args[0]
    ----[[
    if (L0.GetState(withdrawID))
    then
        print("ERR :" .. CName ..  " launch --- id alreay exist")
        return false
    end
    local txInfo = L0.TxInfo()
    local sender = txInfo["Sender"]
    local assetID = txInfo["AssetID"]
    local amount = txInfo["Amount"]
    if (type(sender) ~= "string")
    then
        print("ERR :" .. CName ..  " launch --- wrong sender")
        return false
    end
    if (type(assetID) ~= "number" or assetID < 0)
    then
        print("ERR :" .. CName ..  " launch --- wrong assetID")
        return false
    end
    if (type(amount) ~= "number" or amount < 0)
    then
        print("ERR :" .. CName ..  " launch --- wrong amount")
        return false
    end
    L0.PutState(prefix..withdrawID, sender.."&"..assetID.."&"..amount)
    --]]--
    return true
end

--  撤销提现, 合约账户转账到发送方，删除提现ID
--  参数： 提现ID
--  前置条件：提现ID存在、发送方正确
function cacel(args)
    -- validate
    if(#args ~= 1)
    then
        print("ERR :" .. CName ..  " cacel --- wrong args number")
        return false
    end
    -- execute
    local withdrawID = "launch_"..args[0]
    ----[[
    withdrawInfo = L0.GetState(withdrawID)
    if (not withdrawInfo) 
    then
        print("ERR :" .. CName ..  " cacel --- id not exist")
        return false
    end
    local txInfo = L0.TxInfo()
    local sender = txInfo["Sender"]
    local tb = string.split(withdrawInfo, "&")
    receiver = tb[1]
    assetID = tb[2]
    amount = tb[3]
    if (receiver ~= sender) 
    then
        print("ERR :" .. CName ..  " cacel --- wrong sender")
        return false
    end
    L0.Transfer(receiver, assetID, amount)
    L0.DelState(withdrawID)
    --]]--
end

-- 提现成功, 合约账户转账到系统账户，手续费转到手续费账户
-- 参数：提现ID、提现手续费
-- 前置条件：发送方为系统账户、提现ID已经存在、 手续费足够
func succeed(args)
    -- validate
    if(#args ~= 2)
    then
        print("ERR :" .. "succeed --- wrong args number")
        return false
    end
    -- execute
    local withdrawID = "launch_"..args[0]
    local feeAmount = args[1]
    if (type(feeAmount) ~= "number" or feeAmount <0) {
        print("ERR :" .. CName ..  " launch --- wrong feeAmount")
        return false
    }
    ----[[
    local system = L0.GetState("account_system")
    local txInfo = L0.TxInfo()
    local sender = txInfo["Sender"]
    if (system ~= sender) 
    then
        print("ERR :" .. CName ..  " succeed --- wrong sender")
        return false
    end

    withdrawInfo = L0.GetState(withdrawID)
    if (not withdrawInfo) 
    then
        print("ERR :" .. CName ..  " succeed --- id not exist")
        return false
    end
    local tb = string.split(withdrawInfo, "&")
    assetID = tb[2]
    amount = tb[3]
    if (account <= feeAmount) 
    then
        print("ERR :" .. CName ..  " succeed --- balance is not enough")
        return false
    end
    fee = L0.GetState("accout_fee")
    L0.Transfer(fee, assetID, feeAmount)
    L0.Transfer(system, assetID, amount-feeAmount)
    L0.DelState(withdrawID)
    --]]--
end

-- 提现失败, 合约账户转账到发送方，并删除提现ID
-- 参数： 提现ID
-- 前置条件：发送方为系统账户、提现ID已经存在、
function fail(args)
    -- validate
    if(#args ~= 1)
    then
        print("ERR :" .. "fail --- wrong args number")
        return false
    end
    -- execute
    local withdrawID = "launch_"..args[0]
    ----[[
    local system = L0.GetState("account_system")
    local txInfo = L0.TxInfo()
    local sender = txInfo["Sender"]
    if (system ~= sender) 
    then
        print("ERR :" .. CName ..  " succeed --- wrong sender, must system")
        return false
    end

    withdrawInfo = L0.GetState(withdrawID)
    if (not withdrawInfo) 
    then
        print("ERR :" .. CName ..  " cacel --- withdrawID not exist")
        return false
    end
    local tb = string.split(withdrawInfo, "&")
    receiver = tb[1]
    assetID = tb[2]
    amount = tb[3]
    L0.Transfer(receiver, assetID, amount)
    L0.DelState(withdrawID)
    --]]--
end