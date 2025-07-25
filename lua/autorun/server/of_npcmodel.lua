CreateConVar("of_garrylord_model_replacement", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_model_randomskin", "0", FCVAR_ARCHIVE, "")
CreateConVar("of_garrylord_model_randombodygroup", "0", FCVAR_ARCHIVE, "")

local activemodelSettings = {}

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


local function ReplaceNPCModel(ent)
  if not IsValid(ent) or not ent:IsNPC() then return end
  local entClass = ent:GetClass()
  if entClass ~= "npc_combine_s" and entClass ~= "npc_citizen" and entClass ~= "npc_metropolice" then return end

  timer.Simple(0.1, function()
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
      if table.HasValue(includedModels, ent:GetModel()) then
        local model = GetRandomNPCModel(entClass)
        if model == nil then return end
        ent:SetModel(model)
      end
    end
  end)

  timer.Simple(0.15, function()
      if not IsValid(ent) then return end

      if GetConVar("of_garrylord_model_randombodygroup"):GetBool() then
          local bodygroups = ent:GetBodyGroups()

          if bodygroups ~= nil and #bodygroups > 1 then
              for id, bodygroup in pairs(bodygroups) do
                  ent:SetBodygroup(id, math.random(0, bodygroup.num))
              end
          end
      end

      if GetConVar("of_garrylord_model_randomskin"):GetBool() then
        local skin_count = ent:SkinCount()

        if skin_count > 1 then
            ent:SetSkin(math.random(0, skin_count - 1))
        end
      end
  end)
end

hook.Add("OnEntityCreated", "OFNPCP_ModelReplacement", ReplaceNPCModel)

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

-- 像是打战役的时候会发生的事情

hook.Add("PlayerInitialSpawn", "OFNPCP_RandomizeMapNPCs", function(ply)
  timer.Simple(5, function()
    for _, npc in pairs(ents.FindByClass("npc_*")) do
      if IsValid(npc) and npc:IsNPC() then
        ReplaceNPCModel(npc)
      end
    end
  end)
end)