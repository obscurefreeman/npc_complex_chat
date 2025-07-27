CreateConVar("of_garrylord_model_replacement", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_model_randomskin", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_model_randombodygroup", "0", FCVAR_ARCHIVE, "")

local activemodelSettings = {}
local blockedBodygroups = {}

net.Receive("OFNPCP_NS_SaveModelSettings", function(len, ply)

  if not IsValid(ply) or not ply:IsSuperAdmin() then return end
  
  local modelSettings = net.ReadTable()
  
  -- 检查目录是否存在，不存在则创建
  if not file.IsDir("of_npcp", "DATA") then
      file.CreateDir("of_npcp")
  end
  
  -- 将选中的模型表转换为JSON格式并保存
  file.Write("of_npcp/model_settings.txt", util.TableToJSON(modelSettings))

  activemodelSettings = modelSettings
end)

local function GetRandomNPCModel(npc_type)
  local model
  local modelPool = activemodelSettings and activemodelSettings[npc_type] or {}
  
  if #modelPool > 0 then
      model = modelPool[math.random(1, #modelPool)]
  end
  return model
end


function OFNPCP_ReplaceNPCModel( ent, identity )
  if not IsValid(ent) or not ent:IsNPC() then return end
  local entClass = identity.info
  if entClass ~= "npc_combine_s" and entClass ~= "npc_citizen" and entClass ~= "npc_metropolice" then return end

  local randommodel, randomskin
  local randombodygroups = {}

  if GetConVar("of_garrylord_model_replacement"):GetBool() then
    if not IsValid(ent) then return end
    
    -- 定义替换的模型列表
    local includedModels = {
    "models/humans/group01/female_01.mdl",
    "models/humans/group01/female_02.mdl",
    "models/humans/group01/female_03.mdl",
    "models/humans/group01/female_04.mdl",
    "models/humans/group01/female_06.mdl",
    "models/humans/group01/female_07.mdl",
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/male_02.mdl",
    "models/humans/group01/male_03.mdl",
    "models/humans/group01/male_04.mdl",
    "models/humans/group01/male_05.mdl",
    "models/humans/group01/male_06.mdl",
    "models/humans/group01/male_07.mdl",
    "models/humans/group01/male_08.mdl",
    "models/humans/group01/male_09.mdl",
    "models/humans/group01/male_cheaple.mdl",
    "models/humans/group02/female_01.mdl",
    "models/humans/group02/female_02.mdl",
    "models/humans/group02/female_03.mdl",
    "models/humans/group02/female_04.mdl",
    "models/humans/group02/female_06.mdl",
    "models/humans/group02/female_07.mdl",
    "models/humans/group02/male_01.mdl",
    "models/humans/group02/male_02.mdl",
    "models/humans/group02/male_03.mdl",
    "models/humans/group02/male_04.mdl",
    "models/humans/group02/male_05.mdl",
    "models/humans/group02/male_06.mdl",
    "models/humans/group02/male_07.mdl",
    "models/humans/group02/male_08.mdl",
    "models/humans/group02/male_09.mdl",
    "models/humans/group03/female_01.mdl",
    "models/humans/group03/female_01_bloody.mdl",
    "models/humans/group03/female_02.mdl",
    "models/humans/group03/female_02_bloody.mdl",
    "models/humans/group03/female_03.mdl",
    "models/humans/group03/female_03_bloody.mdl",
    "models/humans/group03/female_04.mdl",
    "models/humans/group03/female_04_bloody.mdl",
    "models/humans/group03/female_06.mdl",
    "models/humans/group03/female_06_bloody.mdl",
    "models/humans/group03/female_07.mdl",
    "models/humans/group03/female_07_bloody.mdl",
    "models/humans/group03/male_01.mdl",
    "models/humans/group03/male_01_bloody.mdl",
    "models/humans/group03/male_02.mdl",
    "models/humans/group03/male_02_bloody.mdl",
    "models/humans/group03/male_03.mdl",
    "models/humans/group03/male_03_bloody.mdl",
    "models/humans/group03/male_04.mdl",
    "models/humans/group03/male_04_bloody.mdl",
    "models/humans/group03/male_05.mdl",
    "models/humans/group03/male_05_bloody.mdl",
    "models/humans/group03/male_06.mdl",
    "models/humans/group03/male_06_bloody.mdl",
    "models/humans/group03/male_07.mdl",
    "models/humans/group03/male_07_bloody.mdl",
    "models/humans/group03/male_08.mdl",
    "models/humans/group03/male_08_bloody.mdl",
    "models/humans/group03/male_09.mdl",
    "models/humans/group03/male_09_bloody.mdl",
    "models/humans/group03m/female_01.mdl",
    "models/humans/group03m/female_02.mdl",
    "models/humans/group03m/female_03.mdl",
    "models/humans/group03m/female_04.mdl",
    "models/humans/group03m/female_06.mdl",
    "models/humans/group03m/female_07.mdl",
    "models/humans/group03m/male_01.mdl",
    "models/humans/group03m/male_02.mdl",
    "models/humans/group03m/male_03.mdl",
    "models/humans/group03m/male_04.mdl",
    "models/humans/group03m/male_05.mdl",
    "models/humans/group03m/male_06.mdl",
    "models/humans/group03m/male_07.mdl",
    "models/humans/group03m/male_08.mdl",
    "models/humans/group03m/male_09.mdl",
    "models/combine_soldier.mdl",
    "models/combine_soldier_prisonguard.mdl",
    "models/combine_super_soldier.mdl"
    }
    
    -- 检查当前模型是否在排除列表中
    if table.HasValue(includedModels, identity.model) then
      local model = GetRandomNPCModel(entClass)
      if model == nil then return end
      randommodel = model
      timer.Simple(0.1, function()
        if not IsValid(ent) then return end
        ent:SetModel(model)
      end)
    end
  end

  if GetConVar("of_garrylord_model_randombodygroup"):GetBool() then
      local bodygroups = ent:GetBodyGroups()

      if bodygroups ~= nil and #bodygroups > 1 then
          for id, bodygroup in pairs(bodygroups) do
            local bodygroupnumber = bodygroup.num - (blockedBodygroups[bodygroup.name] and 1 or 0)
            local randomNum = math.random(0, math.max(0, bodygroupnumber))
            table.insert(randombodygroups, {id = id, num = randomNum})
            timer.Simple(0.15, function()
              if not IsValid(ent) then return end
              ent:SetBodygroup(id, randomNum)
            end)
          end
      end
  end

  if GetConVar("of_garrylord_model_randomskin"):GetBool() then
    local skin_count = ent:SkinCount()

    if skin_count > 1 then
        randomskin = math.random(0, skin_count - 1)
        timer.Simple(0.15, function()
          if not IsValid(ent) then return end
          ent:SetSkin(randomskin)
        end)
    end
  end

  -- 打印生成的随机模型、身体组和皮肤信息
  -- if randommodel then
  --   print("[OFNPCP] 随机模型: " .. randommodel)
  -- end
  -- if randombodygroups and #randombodygroups > 0 then
  --   print("[OFNPCP] 随机身体组:")
  --   for _, bg in ipairs(randombodygroups) do
  --     print("  ID: " .. bg.id .. ", 值: " .. bg.num)
  --   end
  -- end
  -- if randomskin then
  --   print("[OFNPCP] 随机皮肤: " .. randomskin)
  -- end

  return randommodel, randombodygroups, randomskin
end

-- 加载json

hook.Add("PlayerSpawn", "OFNPCP_LoadTables", function(ply)
  if file.Exists("of_npcp/model_settings.txt", "DATA") then
    local savedData = file.Read("of_npcp/model_settings.txt", "DATA")
    if savedData then
      local loadedModels = util.JSONToTable(savedData)
      if loadedModels then
        activemodelSettings = loadedModels
      end
    end
  end
end)

-- 在服务器启动时加载模型设置
hook.Add("Initialize", "OFNPCP_LoadTablesOnInit", function()
  if file.Exists("of_npcp/model_settings.txt", "DATA") then
    local savedData = file.Read("of_npcp/model_settings.txt", "DATA")
    if savedData then
      local loadedModels = util.JSONToTable(savedData)
      if loadedModels then
        activemodelSettings = loadedModels
      end
    end
  end
end)

net.Receive("OFNPCP_NS_SaveBlockedBodygroups", function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    
    local bodygroups = net.ReadTable()
    
    -- 检查目录是否存在，不存在则创建
    if not file.IsDir("of_npcp", "DATA") then
        file.CreateDir("of_npcp")
    end
    
    -- 将被屏蔽的身体组转换为JSON格式并保存
    file.Write("of_npcp/model_bodygroups_block_settings.txt", util.TableToJSON(bodygroups))

    blockedBodygroups = bodygroups
end)