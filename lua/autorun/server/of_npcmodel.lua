CreateConVar("of_garrylord_model_randommodel", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_model_randomskin", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_model_randombodygroup", "0", FCVAR_ARCHIVE, "")

local activemodelSettings

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
  
  -- 如果模型池不为空，则随机选择一个模型
  if #modelPool > 0 then
      model = modelPool[math.random(1, #modelPool)]
  end

  print("[OFNPCP] 随机模型调试信息:")
  print("模型设置: " .. (activemodelSettings and "已加载" or "未加载"))
  print("NPC类型: " .. (npc_type or "未知"))
  print("模型池: " .. (modelPool and #modelPool or 0) .. " 个模型")
  print("选择的模型: " .. (model or "无"))

  return model
end

local function randomize_bodygroups(ent)
  local bodygroups = ent:GetBodyGroups()

  if bodygroups ~= nil and #bodygroups > 1 then
      for id, bodygroup in pairs(bodygroups) do
          ent:SetBodygroup(id, math.random(0, bodygroup.num))
      end
  end
end

local function randomize_skins(ent)
  local skin_count = ent:SkinCount()

  if skin_count > 1 then
      ent:SetSkin(math.random(0, skin_count - 1))
  end
end

hook.Add("OnEntityCreated", "OFNPCP_ModelReplacement", function(ent)
  if not IsValid(ent) or not ent:IsNPC() then return end
  local entClass = ent:GetClass()
  if entClass ~= "npc_combine_s" and entClass ~= "npc_citizen" and entClass ~= "npc_metropolice" then return end

  timer.Simple(0.1, function()
      if not IsValid(ent) then return end
      model = GetRandomNPCModel(entClass)
      if model == nil then return end
      ent:SetModel(model)
  end)

  timer.Simple(0.15, function()
      if not IsValid(ent) then return end

      if GetConVar("of_garrylord_model_randombodygroup"):GetBool() then
          randomize_bodygroups(ent)
      end

      if GetConVar("of_garrylord_model_randomskin"):GetBool() then
          randomize_skins(ent)
      end
  end)
end)

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

-- 像是打战役的时候会发生的事情

hook.Add("PlayerInitialSpawn", "OFNPCP_RandomizeMapNPCs", function(ply)
  timer.Simple(5, function()

  end)
end)