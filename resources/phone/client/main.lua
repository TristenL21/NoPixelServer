local guiEnabled = false
local hasOpened = false
local lstMsgs = {}
local lstContacts = {}
local inPhone = false
local radioChannel = math.random(1,999)
local usedFingers = false
local dead = false
local onhold = false
local YellowPageArray = {}
local PhoneBooth = GetEntityCoords(PlayerPedId())
local AnonCall = false
local phoneNotifications = true
local insideDelivers = false
local curhrs = 9
local curmins = 2
local allowpopups = true
local vehicles = {}
local isDead = false
local isNotInCall, isDialing, isReceivingCall, isCallInProgress = 0, 1, 2, 3
local callStatus = isNotInCall

RegisterNetEvent("np-jobmanager:playerBecameJob")
AddEventHandler("np-jobmanager:playerBecameJob", function(job)
    if job == "trucker" then
        trucker = true
    end
end)

function getCardinalDirectionFromHeading()
  local heading = GetEntityHeading(PlayerPedId())
  if heading >= 315 or heading < 45 then
      return "North Bound"
  elseif heading >= 45 and heading < 135 then
      return "West Bound"
  elseif heading >=135 and heading < 225 then
      return "South Bound"
  elseif heading >= 225 and heading < 315 then
      return "East Bound"
  end
end

function SetCustomNuiFocus(hasKeyboard, hasMouse)
  HasNuiFocus = hasKeyboard or hasMouse

  SetNuiFocus(hasKeyboard, hasMouse)
  SetNuiFocusKeepInput(HasNuiFocus)

  TriggerEvent("np:voice:focus:set", HasNuiFocus, hasKeyboard, hasMouse)
end

RegisterNUICallback('btnNotifyToggle', function(data, cb)
    allowpopups = not allowpopups
    if allowpopups then
      TriggerEvent("DoLongHudText","Popups Enabled")
    else
      TriggerEvent("DoLongHudText","Popups Disabled")
    end
end)


activeTasks = {
  --[1] = { ["Gang"] = 2, ["TaskType"] = 1, ["TaskState"] = 2, ["TaskOwner"] = 12(cid), ["TaskInfo"] = , ["location"] = { ['x'] = -1248.52,['y'] = -1141.12,['z'] = 7.74,['h'] = 284.71, ['info'] = 'Down at Smokies on the Beach' }, }
}

activeNumbersClient = {}

RegisterNetEvent('phone:reset')
AddEventHandler('phone:reset', function(cidsent)
  if guiEnabled then
    closeGui2()
  end
  guiEnabled = false
  hasOpened = false
  lstMsgs = {}
  lstContacts = {}
  vehicles = {}
  radioChannel = math.random(1,999)
  dead = false
  onhold = false
  inPhone = false
end)

RegisterNetEvent('Yougotpaid')
AddEventHandler('Yougotpaid', function(cidsent)
    local cid = exports["isPed"]:isPed("cid")
    if tonumber(cid) == tonumber(cidsent) then
        TriggerEvent("DoLongHudText","Life Invader Payslip Generated.")
    end
end)
           
RegisterNetEvent('Payment:Successful')
AddEventHandler('Payment:Successful', function()
    SendNUIMessage({
        openSection = "error",
        textmessage = "Payment Processed.",
    })     
end)

RegisterNetEvent('warrants:AddInfo')
AddEventHandler('warrants:AddInfo', function(name, charges)

    openGuiNow()

    SendNUIMessage({
      openSection = "enableoutstanding",
    })
    for i = 1, #charges do

      SendNUIMessage({
        openSection = "inputoutstanding",
        textmessage = charges[i],
      })
    end
    
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if IsControlJustPressed(0, 199) then
      SetPauseMenuActive(false)
    end
  end
end)



RegisterNetEvent("phone:listREproperties")
AddEventHandler("phone:listREproperties", function(outstandingArray)
    openGuiNow()
    SendNUIMessage({
      openSection = "showOutstandingPayments",
      outstandingPayments = outstandingArray
    })
    -- finish outstanding payments here.
end)

RegisterNetEvent("phone:listunpaid")
AddEventHandler("phone:listunpaid", function(outstandingArray)

  SendNUIMessage({
    openSection = "showOutstandingPayments",
    outstandingPayments = outstandingArray
  })
    -- finish outstanding payments here.
end)

RegisterNetEvent("phone:activeNumbers")
AddEventHandler("phone:activeNumbers", function(activePhoneNumbers)
  activeNumbersClient = activePhoneNumbers
  hasOpened = false
end)


RegisterNetEvent("gangTasks:updateClients")
AddEventHandler("gangTasks:updateClients", function(newTasks)
  activeTasks = newTasks
end)

TaskState = {
  [1] = "Ready For Pickup",
  [2] = "In Process",
  [3] = "Successful",
  [4] = "Failed",
  [5] = "Delivered with Damaged Goods",
}

TaskTitle = {
  [1] = "Ordering 'Take-Out'",
  [2] = "Ordering 'Disposal Service'",
  [3] = "Ordering 'Postal Delivery'",
  [4] = "Ordering 'Hot Food Room Service'",
}

function findTaskIdFromBlockChain(blockchain)
  local retnum = 1
  for i = 1, #activeTasks do
    if activeTasks[i]["BlockChain"] == blockchain then
      retnum = i
    end
  end
  return retnum
end

-- real estate nui app responses

function loading()
    SendNUIMessage({
        openSection = "error",
        textmessage = "Loading, please wait.",
    })  
end
local ownedkeys = {}
local sharedkeys = {}

RegisterNetEvent("phone:setServerTime")
AddEventHandler("phone:setServerTime", function(time)
  SendNUIMessage({
    openSection = "server-time",
    serverTime = time
  })
end)

TriggerServerEvent("phone:getServerTime")

RegisterNetEvent("timeheader")
AddEventHandler("timeheader", function(hrs,mins)


  if hrs < 10 then
    hrs = "0"..hrs
  end
  if mins < 10 then
    mins = "0"..mins
  end
  curhrs = hrs
  curmins = mins

  local timesent = curhrs .. ":" .. curmins
  if guiEnabled then
    SendNUIMessage({
      openSection = "timeheader",
      timestamp = timesent,
    })   
  end
end)
function doTimeUpdate()
  local timesent = curhrs .. ":" .. curmins
  if guiEnabled then
    SendNUIMessage({
      openSection = "timeheader",
      timestamp = timesent,
    })   
  end
end
RegisterNetEvent("returnPlayerKeys")
AddEventHandler("returnPlayerKeys", function(ownedkeys,sharedkeys)
  print("keys triggered")

      if not guiEnabled then
        return
      end

      SendNUIMessage({
        openSection = "keys",
        keys = {
          sharedKeys = sharedkeys,
          ownedKeys = ownedkeys
        }
      })
end)

function CellFrontCamActivate(activate)
	return Citizen.InvokeNative(0x2491A93618B7D838, activate)
end

local selfieMode = false
RegisterNUICallback('phone:selfie', function()
  selfieMode = not selfieMode
  if selfieMode then
    closeGui()
    DestroyMobilePhone()
    CreateMobilePhone(4)
    CellCamActivate(true, true)
    CellFrontCamActivate(true)
  else
    closeGui()
    CellCamActivate(false, false)
    CellFrontCamActivate(false)
    DestroyMobilePhone()
    selfieMode = false
  end
end)

RegisterNUICallback('btnPropertyOutstanding', function(data, cb)
    loading()
    TriggerServerEvent("houses:PropertyOutstanding")
end)

RegisterNUICallback('removeSharedKey', function(data)
  TriggerServerEvent('houses:removeSharedKey', data.house_id, data.house_model)
end)

RegisterNUICallback('btnMortgage', function(data, cb)
    TriggerEvent("houses:Mortgage")
    loading()
    Citizen.Wait(400)
    TriggerServerEvent("ReturnHouseKeys")
    
end)

RegisterNUICallback('btnFurniture', function(data, cb)
    closeGui()
    TriggerEvent("openFurniture")
end)

RegisterNUICallback('btnGiveKey', function(data, cb)
    TriggerEvent("houses:GiveKey")
end)

RegisterNUICallback('btnWipeKeys', function(data, cb)
    TriggerEvent("houses:WipeKeys")
end)


RegisterNUICallback('btnProperty2', function(data, cb)
    loading()
    TriggerServerEvent("ReturnHouseKeys")
end)

RegisterNUICallback('btnProperty', function(data, cb)
    loading()
    local realEstateRank = GroupRank("real_estate")
    if realEstateRank > 0 then
      SendNUIMessage({
          openSection = "RealEstate",
          RERank = realEstateRank
      })        
    end
end)

RegisterNUICallback('btnPropertyModify', function(data, cb)
  TriggerEvent("housing:info:realtor","modify")
end)

RegisterNUICallback('btnPropertyReset', function(data, cb)
  TriggerEvent("housing:info:realtor","reset")
end)

RegisterNUICallback('btnPropertyClothing', function(data, cb)
  TriggerEvent("housing:info:realtor","setclothing")
end)

RegisterNUICallback('btnPropertyStorage', function(data, cb)
  TriggerEvent("housing:info:realtor","setstorage")
end)

RegisterNUICallback('btnPropertySetGarage', function(data, cb)
  TriggerEvent("housing:info:realtor","setgarage")
end)

RegisterNUICallback('btnPropertyWipeGarages', function(data, cb)
  TriggerEvent("housing:info:realtor","wipegarages")
end)

RegisterNUICallback('btnPropertySetBackdoorInside', function(data, cb)
  TriggerEvent("housing:info:realtor","backdoorinside")
end)

RegisterNUICallback('btnPropertySetBackdoorOutside', function(data, cb)
  TriggerEvent("housing:info:realtor","backdooroutside")
end)

RegisterNUICallback('btnPropertyUpdateHouse', function(data, cb)
  TriggerEvent("housing:info:realtor","update")
end)

RegisterNUICallback('btnRemoveSharedKey', function(data, cb)
  TriggerEvent("housing:info:realtor","update")
end)

RegisterNUICallback('btnPropertyUnlock', function(data, cb)
  TriggerEvent("housing:info:realtor","unlock")
end)

RegisterNUICallback('btnPropertyHouseCreationPoint', function(data, cb)
  TriggerEvent("housing:info:realtor","creationpoint")
end)
RegisterNUICallback('btnPropertyStopHouse', function(data, cb)
  TriggerEvent("housing:info:realtor","stop")
end)
RegisterNUICallback('btnAttemptHouseSale', function(data, cb)
  TriggerEvent("housing:sendPurchaseAttempt",data.cid,data.price)
end)
RegisterNUICallback('btnTransferHouse', function(data, cb)
  TriggerEvent("housing:transferHouseAttempt", data.cid)
end)
RegisterNUICallback('btnEvictHouse', function(data, cb)
  TriggerEvent("housing:evictHouseAttempt")
end)

-- real estate nui app responses end











RegisterNUICallback('btnGiveTaskToPlayer', function(data, cb)
    TriggerServerEvent("Tasks:AttemptGive",data.taskid,data.targetid)
end)

RegisterNUICallback('trackTaskLocation', function(data, cb)
    local taskID = findTaskIdFromBlockChain(data.TaskIdentifier)
    TriggerEvent("DoLongHudText","Location Set",15)

    SetNewWaypoint(activeTasks[taskID]["Location"]["x"],activeTasks[taskID]["Location"]["y"])
end)

function GroupName(groupid)
  local name = "Error Retrieving Name"
  local mypasses = exports["isPed"]:isPed("passes")
  for i=1, #mypasses do
    if mypasses[i]["pass_type"] == groupid then
      name = mypasses[i]["business_name"]
    end 
  end
  return name
end

function GroupRank(groupid)
  local rank = 0
  local mypasses = exports["isPed"]:isPed("passes")
  for i=1, #mypasses do
    if mypasses[i]["pass_type"] == groupid then
      rank = mypasses[i]["rank"]
    end 
  end
  return rank
end

RegisterNUICallback('bankGroup', function(data)
    local gangid = data.gangid
    local cashamount = data.cashamount
    print(json.encode(data))
    TriggerServerEvent("server:gankGroup", gangid,cashamount)
end)

RegisterNUICallback('payGroup', function(data)
    local gangid = data.gangid
    local cid = data.cid
    local cashamount = data.cashamount
    TriggerServerEvent("server:givepayGroup", gangid,cashamount,cid)
end)

RegisterNUICallback('promoteGroup', function(data)
    local gangid = data.gangid
    local cid = data.cid
    local newrank = data.newrank
    SendNUIMessage({
        openSection = "error",
        textmessage = "Loading, please wait.",
    })
    TriggerServerEvent("server:givepass", gangid,newrank,cid)
end)


RegisterNUICallback('callNumber', function(data)
    closeGui()
    local number = data.callnum
    TriggerServerEvent("phone:callContact",number,true)
end)
RegisterNUICallback('manageGroup', function(data)
    local groupid = data.GroupID
    
    if rank < 2 then
      SendNUIMessage({
        openSection = "error",
        textmessage = "Permission Error",
      })   
      return
    end

    SendNUIMessage({
        openSection = "error",
        textmessage = "Loading, please wait.",
    })   

    TriggerServerEvent("group:pullinformation",groupid,rank)

end)

RegisterNetEvent("phone:error")
AddEventHandler("phone:error", function()
      SendNUIMessage({
        openSection = "error",
        textmessage = "<b>Network Error</b> <br><br> Please contact support if this error persists, thank you for using Evolved Phone Services.",
      })   
end)



RegisterNetEvent("group:fullList")
AddEventHandler("group:fullList", function(result,bank,groupid,rank)

    -- group-manage
    local groupname = GroupName(groupid)
    SendNUIMessage({
      openSection = "groupManage",
      groupData = {
        groupName = groupname,
        bank = bank,
        groupId = groupid,
        employees = result,
        rank = rank
      }
    })
    --[[
    SendNUIMessage({
      openSection = "GroupManager",
      sentbank = "<b>" .. groupname .. "</b> <br> Banked Money: $" .. bank,
      sentgroupid = groupid,
    }) 

    for i,v in pairs(result) do
        SendNUIMessage({
          openSection = "GroupManagerUpdate",
          info = v
        }) 
    end]]--

end)

-- associate is a legal worker
-- manager is a legal management worker, can pay / hire / remove below.
-- Partner is associated with "other" business activities and can not alter legal workers.
-- Part-Time Manager is associated with "other" business activites but can also manage legal workers, can pay / hire / remove below.
-- CEO runs that shit dawg, can pay / hire / remove below.


local recentcalls = {}

RegisterNUICallback('getCallHistory', function()
  SendNUIMessage({
    openSection = "callHistory",
    callHistory = recentcalls
  })
end)




RegisterNUICallback('btnTaskGroups', function()

    local mypasses = exports["isPed"]:isPed("passes")

    local groupObject = {}
    for i = 1, #mypasses do
        local rankConverted = "No Association"
        rank = mypasses[i]["rank"]
        if rank == 1 then
          rankConverted = "Associate"
        elseif rank == 2 then
          rankConverted = "Management"
        elseif rank == 3 then
          rankConverted = "Partner"
        elseif rank == 4 then
          rankConverted = "Part-Time Manager"
        elseif rank == 5 then
          rankConverted = "CEO"
        end
        if rank > 0 then
          table.insert(groupObject, {
            namesent = mypasses[i]["business_name"],
            ranksent = rankConverted,
            idsent = mypasses[i]["pass_type"]
          })
        end
    end

    SendNUIMessage({
      openSection = "groups",
      groups = groupObject
    })
end)






RegisterNUICallback('btnTaskGang', function()
  TriggerEvent("gangTasks:updated")
end)



local pcs = {
  [1] = 1333557690,
  [2] = -1524180747, 
}


function IsNearPC()
  for i = 1, #pcs do
    local objFound = GetClosestObjectOfType( GetEntityCoords(PlayerPedId()), 0.75, pcs[i], 0, 0, 0)

    if DoesEntityExist(objFound) then
      TaskTurnPedToFaceEntity(PlayerPedId(), objFound, 3.0)
      return true
    end
  end

  if #(GetEntityCoords(PlayerPedId()) - vector3(1272.27, -1711.91, 54.78)) < 1.0 then
    SetEntityHeading(PlayerPedId(),14.0)
    return true
  end
  if #(GetEntityCoords(PlayerPedId()) - vector3(1275.4, -1710.52, 54.78)) < 5.0 then
    SetEntityHeading(PlayerPedId(),300.0)
    return true
  end


  return false
end


RegisterNetEvent("open:deepweb")
AddEventHandler("open:deepweb", function()
    SetCustomNuiFocus(false,false)
    SetCustomNuiFocus(true,true)
  guiEnabled = true
  SendNUIMessage({
    openSection = "deepweb" 
  })
end)

RegisterNetEvent("gangTasks:updated")
AddEventHandler("gangTasks:updated", function()
  local gang = exports["isPed"]:isPed("gang")
  local cid = tonumber(exports["isPed"]:isPed("cid"))

  local taskObject = {}
  for i = 1, #activeTasks do

    if activeTasks[i]["Gang"] ~= 0 and gang ~= 0 and tonumber(activeTasks[i]["taskOwnerCid"]) ~= cid then
      if gang == activeTasks[i]["Gang"] then
        taskObject[#taskObject + 1 ] = {
          name = TaskTitle[activeTasks[i]["TaskType"]],
          assignedTo = activeTasks[i]["taskOwnerCid"],
          status = TaskState[activeTasks[i]["TaskState"]],
          identifier = activeTasks[i]["BlockChain"],
          groupId = gang,
          retrace = 0,
        }
      end
    elseif activeTasks[i]["Gang"] == 0 and tonumber(activeTasks[i]["taskOwnerCid"]) ~= cid then

      local passes = exports["isPed"]:isPed("passes")
      for z = 1, #passes do

        local passType = activeTasks[i]["Group"]
        if passes[z].pass_type == passType and (passes[z].rank == 2 or passes[z].rank > 3) then
          taskObject[#taskObject + 1 ] = {
            name = activeTasks[i]["TaskNameGroup"],
            assignedTo = activeTasks[i]["taskOwnerCid"],
            status = TaskState[activeTasks[i]["TaskState"]],
            identifier = activeTasks[i]["BlockChain"],
            groupId = passType,
            retrace = 0,
          }
        end

      end

    else
      if tonumber(activeTasks[i]["taskOwnerCid"]) == cid then

        local TaskName = ""
        if activeTasks[i]["Gang"] == 0 then
          TaskName = activeTasks[i]["TaskNameGroup"]
        else
          TaskName = TaskTitle[activeTasks[i]["TaskType"]]
        end
        taskObject[#taskObject + 1 ] = {
          name = TaskName,
          assignedTo = activeTasks[i]["taskOwnerCid"],
          status = TaskState[activeTasks[i]["TaskState"]],
          identifier = activeTasks[i]["BlockChain"],
          groupId = gang,
          retrace = 1
        }
      end
    end
  end

  SendNUIMessage({
    openSection = "addTasks",
    tasks = taskObject
  })
end)

RegisterNetEvent("purchasePhone")
AddEventHandler("purchasePhone", function()
  TriggerServerEvent("purchasePhone")
end)

RegisterNUICallback('btnMute', function()
  if phoneNotifications then
    TriggerEvent("DoShortHudText", "Notifications Disabled.",10)
  else
    TriggerEvent("DoShortHudText", "Notifications Enabled.",10)
  end
  phoneNotifications = not phoneNotifications
end)

RegisterNetEvent("tryTweet")
AddEventHandler("tryTweet", function(tweetinfo,message,user)
  if hasPhone() then
    TriggerServerEvent("AllowTweet",tweetinfo,message)
  end
end)

RegisterNUICallback('btnDecrypt', function()
  TriggerEvent("secondaryjob:accepttask")
end)



RegisterNUICallback('btnGarage', function()
  TriggerServerEvent("garages:CheckGarageForVeh")
end)

RegisterNUICallback('btnHelp', function()
  closeGui()
  TriggerEvent("openWiki")
end)

RegisterNUICallback('carpaymentsowed', function()
  TriggerEvent("car:carpaymentsowed")
end)

RegisterNUICallback('vehspawn', function(data)
  findVehFromPlateAndSpawn(data.vehplate)

end)

RegisterNUICallback('vehtrack', function(data)
  findVehFromPlateAndLocate(data.vehplate)
end)

RegisterNUICallback('vehiclePay', function(data)
  TriggerServerEvent('car:dopayment', data.vehiclePlate)
  print(data.vehiclePlate)
end)

function findVehFromPlateAndLocate(plate)

  for ind, value in pairs(vehicles) do

      vehPlate = value.license_plate
    if vehPlate == plate then

      
      state = value.vehicle_state
      coordlocation = value.coords
      SetNewWaypoint(coordlocation[1], coordlocation[2])

    end

  end
  
end

local fakePlates = {}
RegisterNetEvent('fakeplate:accepted')
AddEventHandler('fakeplate:accepted', function(newplate,isStolen,oldplate)
  if isStolen == false then
    fakePlates[newplate] = nil
  else
    fakePlates[oldplate] = newplate
  end
end)

local recentspawnrequest = false
function findVehFromPlateAndSpawn(plate)
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    return
  end
  local fakeplate = nil
  if fakePlates[plate] ~= nil then
    fakeplate = fakePlates[plate]
  end

  for ind, value in pairs(vehicles) do

    vehPlate = value.license_plate
    if vehPlate == plate then
      state = value.vehicle_state
      coordlocation = value.coords

      if #(vector3(coordlocation[1],coordlocation[2],coordlocation[3]) - GetEntityCoords(PlayerPedId())) < 10.0 and state == "Out" then
        local DoesVehExistInProximity = nil
        if fakeplate ~= nil then
          DoesVehExistInProximity = CheckExistenceOfVehWithPlate(fakeplate)
          fakePlates[plate] = nil
        else
          DoesVehExistInProximity = CheckExistenceOfVehWithPlate(vehPlate)
        end

        if not DoesVehExistInProximity and not recentspawnrequest then
          recentspawnrequest = true
          TriggerServerEvent("garages:phonespawn",vehPlate)
          Wait(10000)
          recentspawnrequest = false
        end
      end
    end
  end
end

RegisterNetEvent("phone:SpawnVehicle")
AddEventHandler('phone:SpawnVehicle', function(vehicle, plate, customized, state, Fuel, coordlocation)
  TriggerEvent("garages:SpawnVehicle", vehicle, plate, customized, state, Fuel, coordlocation)
end)



Citizen.CreateThread(function()
    local invehicle = false
    local plateupdate = "None"
    local vehobj = 0
    while true do
        Wait(1000)
        if not invehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
          local playerPed = PlayerPedId()
          local veh = GetVehiclePedIsIn(playerPed, false)
            if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
              vehobj = veh
              local checkplate = GetVehicleNumberPlateText(veh)
              invehicle = true
              plateupdate = checkplate
              local coords = GetEntityCoords(vehobj)
              coords = { coords["x"], coords["y"], coords["z"] }
              TriggerServerEvent("vehicle:coords",plateupdate,coords)
            end
        end
        if invehicle and not IsPedInAnyVehicle(PlayerPedId(), false) then
          local coords = GetEntityCoords(vehobj)
          coords = { coords["x"], coords["y"], coords["z"] }
          TriggerServerEvent("vehicle:coords",plateupdate,coords)
          invehicle = false
          plateupdate = "None"
          vehobj = 0
        end  
    end
end)


function CheckExistenceOfVehWithPlate(platesent)
    local playerped = PlayerPedId()
    local playerCoords = GetEntityCoords(playerped)
    local handle, scannedveh = FindFirstVehicle()
    local success
    local rped = nil
    local distanceFrom
    repeat
        local pos = GetEntityCoords(scannedveh)
        local distance = #(playerCoords - pos)
          if distance < 50.0 then
            local checkplate = GetVehicleNumberPlateText(scannedveh)
            if checkplate == platesent then
              return true
            end
          end
        success, scannedveh = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return false
end




RegisterNetEvent("phone:Garage")
AddEventHandler("phone:Garage", function(vehs)
  vehicles = vehs
  local showCarPayments = false
  local rankCarshop = exports["isPed"]:GroupRank("car_shop")
  local rankImport = exports["isPed"]:GroupRank("illegal_carshop")
  local job = exports["isPed"]:isPed("myjob")


  if rankCarshop > 0 or rankImport > 0 or job == "judge" or job == "police" then
    showCarPayments = true
  end

  local parsedVehicleData = {}
  for ind, value in pairs(vehs) do
    enginePercent = value.engine_damage / 10
    bodyPercent = value.body_damage / 10
    vehName = value.name
    vehPlate = value.license_plate
    currentGarage = value.current_garage
    state = value.vehicle_state
    --coordlocation = value.coords
    allowspawnattempt = 0
    print('dsad', value.last_payment)
    --if #(vector3(coordlocation[1], coordlocation[2], coordlocation[3]) - GetEntityCoords(PlayerPedId())) < 20.0 and state == "Out" then
      --allowspawnattempt = 1
    --end
  
    table.insert(parsedVehicleData, {
      name = vehName,
      plate = vehPlate,
      garage = currentGarage,
      state = state,
      enginePercent = enginePercent,
      bodyPercent = bodyPercent,
      payments = value.payments_left, -- total payments left
      lastPayment = value.last_payment, -- Days left
      amountDue = value.financed, -- amount due
      canSpawn = 0
    })
  end
  
  SendNUIMessage({ openSection = "Garage", showCarPaymentsOwed = showCarPayments, vehicleData = parsedVehicleData})
end)


function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
--[[ 
RegisterNetEvent("phone:Garage")
AddEventHandler("phone:Garage", function(vehs)
  SendNUIMessage({openSection = "closeQuick"})
    vehicles = vehs
    SendNUIMessage({
      openSection = "garages"
    })

    local rankCarshop = exports["isPed"]:GroupRank("car_shop")
    local rankImport = exports["isPed"]:GroupRank("illegal_carshop")

    local job = exports["isPed"]:isPed("myjob")

    if rankCarshop > 0 or rankImport > 0 or job == "judge" or job == "police" then
      SendNUIMessage({
        openSection = "carpaymentsowed"
      })
    end


    for ind, value in pairs(vehs) do
      enginePercent = value.engine_damage / 10
      bodyPercent = value.body_damage / 10
      vehName = value.name
      vehPlate = value.license_plate
      currentGarage = value.current_garage
      damages = " Engine %:" .. enginePercent .. " Body %:" .. bodyPercent .. ""
      state = value.vehicle_state
      currentGarage = currentGarage .. "(" .. state .. ")"
      coordlocation = value.coords
      allowspawnattempt = 0
      print(#(vector3(coordlocation[1],coordlocation[2],coordlocation[3]) - GetEntityCoords(PlayerPedId())))
      if #(vector3(coordlocation[1],coordlocation[2],coordlocation[3]) - GetEntityCoords(PlayerPedId())) < 20.0 and state == "Out" then
        allowspawnattempt = 1
      end
      SendNUIMessage
      ({
        openSection = "addcar",
        name = vehName,
        plate = vehPlate,
        garage = currentGarage,
        damages = damages,
        payments = value.payments,
        last_payment = value.last_payment,
        amount_due = value.amount_due,
        canspawn = allowspawnattempt
      })
    end
    
end)
--]]
local pickuppoints = {
  [1] =  { ['x'] = 923.94,['y'] = -3037.88,['z'] = 5.91,['h'] = 270.81, ['info'] = ' Shipping Container BMZU 822693' },
  [2] =  { ['x'] = 938.02,['y'] = -3026.28,['z'] = 5.91,['h'] = 265.85, ['info'] = ' Shipping Container BMZU 822693' },
  [3] =  { ['x'] = 1006.17,['y'] = -3028.94,['z'] = 5.91,['h'] = 269.31, ['info'] = ' Shipping Container BMZU 822693' },
  [4] =  { ['x'] = 1020.42,['y'] = -3044.91,['z'] = 5.91,['h'] = 87.37, ['info'] = ' Shipping Container BMZU 822693' },
  [5] =  { ['x'] = 1051.75,['y'] = -3045.09,['z'] = 5.91,['h'] = 268.37, ['info'] = ' Shipping Container BMZU 822693' },
  [6] =  { ['x'] = 1134.92,['y'] = -2992.22,['z'] = 5.91,['h'] = 87.9, ['info'] = ' Shipping Container BMZU 822693' },
  [7] =  { ['x'] = 1149.1,['y'] = -2976.06,['z'] = 5.91,['h'] = 93.23, ['info'] = ' Shipping Container BMZU 822693' },
  [8] =  { ['x'] = 1121.58,['y'] = -3042.39,['z'] = 5.91,['h'] = 88.49, ['info'] = ' Shipping Container BMZU 822693' },
  [9] =  { ['x'] = 830.58,['y'] = -3090.46,['z'] = 5.91,['h'] = 91.15, ['info'] = ' Shipping Container BMZU 822693' },
  [10] =  { ['x'] = 830.81,['y'] = -3082.63,['z'] = 5.91,['h'] = 271.61, ['info'] = ' Shipping Container BMZU 822693' },
  [11] =  { ['x'] = 909.91,['y'] = -2976.51,['z'] = 5.91,['h'] = 271.02, ['info'] = ' Shipping Container BMZU 822693' },
}


function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end
blip = 0

function CreateBlip(location)
    DeleteBlip()
    blip = AddBlipForCoord(location["x"],location["y"],location["z"])
    SetBlipSprite(blip, 514)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pick Up")
    EndTextCommandSetBlipName(blip)
end
function DeleteBlip()
  if DoesBlipExist(blip) then
    RemoveBlip(blip)
  end
end

function refreshmail()
    lstnotifications = {}
    for i = 1, #curNotifications do

        local message2 = {
          id = tonumber(i),
          name = curNotifications[tonumber(i)].name,
          message = curNotifications[tonumber(i)].message
        }
        lstnotifications[#lstnotifications+1]= message2
    end
    SendNUIMessage({openSection = "notifications", list = lstnotifications})
end

function rundropoff(boxcount,costs)
  -- delete this line to enable weed boxes 1 ~= 2 should be curhrs ~= curmins
  if 1 ~= 2 then
    for i = 1, math.random(20) do
      TriggerEvent("chatMessage", "SPAM EMAIL ", 8, "This message was blocked for your safety. Thank you for using Evolved mail services.")
    end
    refreshmail()
    return
  end
  local success = true
  local timer = 600000
  TriggerEvent("chatMessage", "EMAIL ", 8, "Yo, here are the coords for the drop off, you have 10 minutes - leave $" .. costs .. " in cash there!")
  refreshmail()
  local location = pickuppoints[math.random(#pickuppoints)]
  CreateBlip(location)
  while timer > 0 do
    Citizen.Wait(1)
    local plycoords = GetEntityCoords(PlayerPedId())
    local dstcheck = #(plycoords - vector3(location["x"],location["y"],location["z"])) 
    if dstcheck < 5.0 then
      DrawText3Ds(location["x"],location["y"],location["z"], "Press E to pickup the dropoff.")
       if dstcheck < 3.0 and IsControlJustReleased(0,38) then
          success = true
          timer = 0
       end
    end
    timer = timer - 1
    if timer == 1 then
      success = false
    end
  end
  if success then
    TriggerServerEvent("weed:phone:buybox",boxcount,costs)
  end
  DeleteBlip()
end


-- turn this to false to re-enable weed purchases.
local waiting = false
RegisterNUICallback('btnBox1', function()
  if waiting then
    return
  end
  waiting = true
  
  Citizen.Wait(math.random(100000))
  rundropoff(1,1500)
  waiting = false
end)

RegisterNUICallback('btnBox2', function()
  if waiting then
    return
  end
  waiting = true
  
  Citizen.Wait(math.random(100000))
  rundropoff(5,4500)
  waiting = false
end)

RegisterNUICallback('btnBox3', function()
  if waiting then
    return
  end
  waiting = true
  
  Citizen.Wait(math.random(100000))
  rundropoff(10,8500)
  waiting = false
end)


RegisterNUICallback('btnBox6', function()
  closeGui()
  TriggerEvent("hacking:attemptHackCrypto","weapon")
end)

RegisterNUICallback('btnBox5', function()
  closeGui()
  TriggerEvent("hacking:attemptHackCrypto","crack")
end)

RegisterNUICallback('btnBox4', function()
  closeGui()
  TriggerEvent("hacking:attemptHackCrypto","bigweapon")
end)

local weaponList = {
  [1] = 324215364,
  [2] = 736523883,
  [3] = 4024951519,
  [4] = 1627465347,
}

local weaponListSmall = {
  [1] = 2017895192,
  [2] = 584646201,
  [3] = 3218215474,
}

local luckList = {
  [1] =  "extended_ap",
  [2] =  "extended_sns",
  [3] =  "extended_micro",
  [4] =  "rifleammo",
  [5] =  "heavyammo",
  [6] =  "lmgammo",
}

RegisterNetEvent("stocks:timedEvent")
AddEventHandler("stocks:timedEvent", function(typeSent)
  local success = true
  local timer = 600000
  TriggerEvent("chatMessage", "EMAIL ", 8, "Yo, here are the coords for the drop off, you have 10 minutes - I already zoinked your Pixerium Credits")
  refreshmail()
  local location = pickuppoints[math.random(#pickuppoints)]
  CreateBlip(location)
  while timer > 0 do
    Citizen.Wait(1)
    local plycoords = GetEntityCoords(PlayerPedId())
    local dstcheck = #(plycoords - vector3(location["x"],location["y"],location["z"])) 
    if dstcheck < 5.0 then
      DrawText3Ds(location["x"],location["y"],location["z"], "Press E to pickup the dropoff.")
       if dstcheck < 3.0 and IsControlJustReleased(0,38) then
          success = true
          timer = 0
       end
    end
    timer = timer - 1
    if timer == 1 then
      success = false
    end
  end

  if success then

    if math.random(1000) == 69 then
      TriggerEvent("player:receiveItem", "741814745", 1)
    end

    if math.random(10) == 1 then
      TriggerEvent("player:receiveItem", ""..luckList[math.random(6)].."", 1)
    end


    if typeSent == "bigweapon" then
      TriggerEvent("player:receiveItem", ""..weaponList[math.random(4)].."", 1)
    end

    if typeSent == "weapon" then
      TriggerEvent("player:receiveItem", ""..weaponListSmall[math.random(3)].."", 1)
    end

  end

  DeleteBlip()
 
end)


function buyItem(typeSent)
  local success = true
  local timer = 600000
  TriggerEvent("chatMessage", "EMAIL ", 8, "Yo, here are the coords for the drop off, you have 10 minutes - it will cost " .. costs .. " Pixerium")
  refreshmail()
  local location = pickuppoints[math.random(#pickuppoints)]
  CreateBlip(location)
  while timer > 0 do
    Citizen.Wait(1)
    local plycoords = GetEntityCoords(PlayerPedId())
    local dstcheck = #(plycoords - vector3(location["x"],location["y"],location["z"])) 
    if dstcheck < 5.0 then
      DrawText3Ds(location["x"],location["y"],location["z"], "Press E to pickup the dropoff.")
       if dstcheck < 3.0 and IsControlJustReleased(0,38) then
          success = true
          timer = 0
       end
    end
    timer = timer - 1
    if timer == 1 then
      success = false
    end
  end
  if success then
    TriggerEvent("crypto:buybox",typeSent,costs)
  end
  DeleteBlip()
end


RegisterNUICallback('btnDelivery', function()
  TriggerEvent("trucker:confirmation")
end)

RegisterNUICallback('btnPackages', function()
  insideDelivers = true
  TriggerEvent("Trucker:GetPackages")
end)

RegisterNUICallback('btnTrucker', function()
  TriggerEvent("Trucker:GetJobs")
end)

RegisterNUICallback('resetPackages', function()
  insideDelivers = false
end)

--[[

for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = #(vector3(targetCoords["x"], targetCoords["y"], targetCoords["z"]) - vector3(plyCoords["x"], plyCoords["y"], plyCoords["z"]))
            if(closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    


]]


RegisterNetEvent("phone:trucker")
AddEventHandler("phone:trucker", function(jobList)

  local deliveryObjects = {}
  for i, v in pairs(jobList) do
    local nameTag = ""
    local itemTag
    local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(v.pickup[1], v.pickup[2], v.pickup[3], currentStreetHash, intersectStreetHash)
    local currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    local intersectStreetName = GetStreetNameFromHashKey(intersectStreetHash)

    local currentStreetHash2, intersectStreetHash2 = GetStreetNameAtCoord(v.drop[1], v.drop[2], v.drop[3], currentStreetHash2, intersectStreetHash2)
    local currentStreetName2 = GetStreetNameFromHashKey(currentStreetHash2)
    local intersectStreetName2 = GetStreetNameFromHashKey(intersectStreetHash2)
    if v.active == 0 then
        table.insert(deliveryObjects, {
          targetStreet = currentStreetName2,
          jobId = v.id,
          jobType = v.JobType
        })
    end
  end 
  SendNUIMessage({
    openSection = "deliveryJob",
    deliveries = deliveryObjects
  })
    
end)

local requestHolder = 0

RegisterNetEvent("phone:packages")
AddEventHandler("phone:packages", function(packages)
  while insideDelivers do
    if requestHolder ~= 0 then
      SendNUIMessage({
        openSection = "packagesWith"
      })
    else
      SendNUIMessage({
        openSection = "packages"
      })
    end
    
    
    for i, v in pairs(packages) do
      if GetPlayerServerId(PlayerId()) == v.source then
        local currentStreetHash2, intersectStreetHash2 = GetStreetNameAtCoord(v.drop[1], v.drop[2], v.drop[3], currentStreetHash2, intersectStreetHash2)
        local currentStreetName2 = GetStreetNameFromHashKey(currentStreetHash2)
        local intersectStreetName2 = GetStreetNameFromHashKey(intersectStreetHash2)

        SendNUIMessage({openSection = "addPackages", street2 = currentStreetName2, jobId = v.id ,distance = getDriverDistance(v.driver , v.drop)})
      end
    end 
    Wait(4000)
  end
end)


RegisterNetEvent("phone:OwnerRequest")
AddEventHandler("phone:OwnerRequest", function(holder)
  requestHolder = holder
end)

RegisterNUICallback('btnRequest', function()
  TriggerServerEvent("trucker:confirmRequest",requestHolder)
  requestHolder = 0
end)




function getDriverDistance(driver , drop)
  local dist = 0

  local ped = GetPlayerPed(value)
  if driver ~= 0 then
    local current = #(vector3(drop[1],drop[2],drop[3]) - GetEntityCoords(ped))
    if current < 15 then
      dist = "Driver at store"
    else
      dist = current
      dist = math.ceil(dist)
    end
    
  else
    dist = "Waiting for driver"
  end

  return dist
end

RegisterNUICallback('selectedJob', function(data, cb)
    TriggerEvent("Trucker:SelectJob",data)
end)

gurgleList = {}
RegisterNetEvent('websites:updateClient')
AddEventHandler('websites:updateClient', function(passedList)
  print(json.encode(passedList))
  gurgleList = passedList

  local gurgleObjects = {}

  if not guiEnabled then
    return
  end

  for i = 1, #gurgleList do
    table.insert(gurgleObjects, {
      webTitle = gurgleList[i]["Title"], 
      webKeywords = gurgleList[i]["Keywords"], 
      webDescription = gurgleList[i]["Description"] 
    })
  end

  SendNUIMessage({ openSection = "gurgleEntries", gurgleData = gurgleObjects})
end)

function isRealEstateAgent()
  if GroupRank("real_estate") > 0 then
    return true
  else
    return false
  end
end

function hasDecrypt2()
    if exports["np-inventory"]:hasEnoughOfItem("vpnxj",1,false) and not exports["isPed"]:isPed("disabled") then
      return true
    else
      return false
    end
end

function hasTrucker()
    if exports["np-base"]:getModule("LocalPlayer"):getVar("job") == "trucker"  then
      print("sex in the truck")
      return true
    else
      print("nop")
      return false
    end
end

function hasDecrypt()
    if exports["np-inventory"]:hasEnoughOfItem("decrypterenzo",1,false) or exports["np-inventory"]:hasEnoughOfItem("decryptersess",1,false) or exports["np-inventory"]:hasEnoughOfItem("decrypterfv2",1,false) and not exports["isPed"]:isPed("disabled") or exports["np-inventory"]:hasEnoughOfItem(80,1,false) and not exports["isPed"]:isPed("disabled") then
      return true
    else
      return false
    end
end

function hasDevice()
    if exports["np-inventory"]:hasEnoughOfItem("mk2usbdevice",1,false) and not exports["isPed"]:isPed("disabled") then
      return true
    else
      return false
    end
end

function hasPhone()
    if
      (
      (exports["np-inventory"]:hasEnoughOfItem("mobilephone",1,false) or 
      exports["np-inventory"]:hasEnoughOfItem("stoleniphone",1,false) or 
      exports["np-inventory"]:hasEnoughOfItem("stolens8",1,false) or
      exports["np-inventory"]:hasEnoughOfItem("stolennokia",1,false) or
      exports["np-inventory"]:hasEnoughOfItem("stolenpixel3",1,false) or
      exports["np-inventory"]:hasEnoughOfItem("boomerphone",1,false))
      and not exports["isPed"]:isPed("disabled") and not exports["isPed"]:isPed("handcuffed")
      ) 
    then
      return true
    else
      return false
    end
end

function hasRadio()
    if exports["np-inventory"]:hasEnoughOfItem("radio",1,false) and not exports["isPed"]:isPed("disabled") then
      return true
    else
      return false
    end
end

function DrawRadioChatter(x,y,z, text,opacity)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    if opacity > 215 then
      opacity = 215
    end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, opacity)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end
local activeMessages = 0

RegisterNetEvent('radiotalkcheck')
AddEventHandler('radiotalkcheck', function(args,senderid)

  if hasRadio() and radioChannel ~= 0 then
    randomStatic(true)

    local ped = GetPlayerPed( -1 )

      if ( DoesEntityExist( ped ) and not IsEntityDead( ped )) then

        loadAnimDict( "random@arrests" )

        TaskPlayAnim(ped, "random@arrests", "generic_radio_chatter", 8.0, 2.0, -1, 50, 2.0, 0, 0, 0 )

        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
      end


    TriggerServerEvent("radiotalkconfirmed",args,senderid,radioChannel)
    Citizen.Wait(2500)
    ClearPedSecondaryTask(PlayerPedId())
  end

end)




function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end 

function randomStatic(loud)
  local vol = 0.05
  if loud then
    vol = 0.9
  end
  local pickS = math.random(4)
  if pickS == 4 then
    TriggerEvent("InteractSound_CL:PlayOnOne","radiostatic1",vol)
  elseif pickS == 3 then
    TriggerEvent("InteractSound_CL:PlayOnOne","radiostatic2",vol)
  elseif pickS == 2 then
    TriggerEvent("InteractSound_CL:PlayOnOne","radiostatic3",vol)
  else
    TriggerEvent("InteractSound_CL:PlayOnOne","radioclick",vol)
  end

end

RegisterNetEvent('radiotalk')
AddEventHandler('radiotalk', function(args,senderid,channel)

    local senderid = tonumber(senderid)

    table.remove(args,1)
    local radioMessage = ""
    for i = 1, #args do
        radioMessage = radioMessage .. " " .. args[i]
    end

    if channel == radioChannel and hasRadio() and radioMessage ~= nil then
      -- play radio click sound locally.
      TriggerEvent('chatMessage', "RADIO #" .. channel, 3, radioMessage, 5000)
      randomStatic(true)

      local radioMessage = ""
      for i = 1, #args do
        if math.random(50) > 25 then
          radioMessage = radioMessage .. " " .. args[i]
        else
          radioMessage = radioMessage .. " **BZZZ** "
        end
      end
      TriggerServerEvent("radiochatter:server",radioMessage)
    end
end)
RegisterNetEvent('radiochatter:client')
AddEventHandler('radiochatter:client', function(radioMessage,senderid)
    if not DoesPlayerExist(senderid) then return end

    local senderid = tonumber(senderid) 
    local location = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(senderid)))
    local dst = #(GetEntityCoords(PlayerPedId()) - location)
    activeMessages = activeMessages + 0.1
    if dst < 5.0 then
      -- play radio static sound locally.
      local counter = 350
      local msgZ = location["z"]+activeMessages
      if PlayerPedId() ~= GetPlayerPed(GetPlayerFromServerId(senderid)) then
        randomStatic(false)
        while counter > 0 and dst < 5.0 do
          location = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(senderid)))
          dst = #(GetEntityCoords(PlayerPedId()) - location)
          DrawRadioChatter(location["x"],location["y"],msgZ, "Radio Chatter: " .. radioMessage, counter)
          counter = counter - 1
          Citizen.Wait(1)
        end
      end
    end
    activeMessages = activeMessages - 0.1 
end)


RegisterNetEvent('radiochannel')
AddEventHandler('radiochannel', function(chan)
  local chan = tonumber(chan)
  if hasRadio() and chan < 1000 and chan > -1 then
    radioChannel = chan
    TriggerEvent("InteractSound_CL:PlayOnOne","radioclick",0.4)
    TriggerEvent('chatMessage', "RADIO CHANNEL " .. radioChannel, 3, "Active", 5000)
    -- play radio click sound.
  end
end)

RegisterNetEvent('canPing')
AddEventHandler('canPing', function(target)
  if hasPhone() and not isDead then
    local crds = GetEntityCoords(PlayerPedId())
    TriggerServerEvent("requestPing", target, crds["x"],crds["y"],crds["z"] )
  else
    TriggerEvent("DoLongHudText","You need a phone to use GPS!",2)
  end
end)

local pingcount = 0
local currentblip = 0
local currentping = { ["x"] = 0.0,["y"] = 0.0,["z"] = 0.0, ["src"] = 0 }
RegisterNetEvent('allowedPing')
AddEventHandler('allowedPing', function(x,y,z,src,name)
  if pingcount > 0 then
    TriggerEvent("DoLongHudText","Somebody sent you a GPS flag but you already have one in process!",2)
    return
  end
  
  if hasPhone() and not isDead then
    pingcount = 5
    currentping = { ["x"] = x,["y"] = y,["z"] = z, ["src"] = src }
    while pingcount > 0 do
      TriggerEvent("DoLongHudText",name .. " has given you a ping location, type /pingaccept to accept",2)
      Citizen.Wait(5000)
      pingcount = pingcount - 1
    end
  else
    TriggerEvent("DoLongHudText","Somebody sent you a GPS flag but you have no phone!",2)
  end
  pingcount = 0
  currentping = { ["x"] = 0.0,["y"] = 0.0,["z"] = 0.0, ["src"] = 0 }
end)

RegisterNetEvent('acceptPing')
AddEventHandler('acceptPing', function()
  if pingcount > 0 then
    if DoesBlipExist(currentblip) then
      RemoveBlip(currentblip)
    end
    currentblip = AddBlipForCoord(currentping["x"], currentping["y"], currentping["z"])
    SetBlipSprite(currentblip, 280)
    SetBlipAsShortRange(currentblip, false)
    BeginTextCommandSetBlipName("STRING")
    SetBlipColour(currentblip, 4)
    SetBlipScale(currentblip, 1.2)
    AddTextComponentString("Accepted GPS Marker")
    EndTextCommandSetBlipName(currentblip)
    TriggerEvent("DoLongHudText","Their GPS ping has been marked on the map")
    TriggerServerEvent("pingAccepted",currentping["src"])
    pingcount = 0
    Citizen.Wait(60000)
    if DoesBlipExist(currentblip) then
      RemoveBlip(currentblip)
    end
  end
end)


--radiotalk
--radiochannel

-- Open Gui and Focus NUI

-- read -- cellphone_text_read_base
-- texting -- cellphone_swipe_screen
-- phone away -- cellphone_text_out


local recentopen = false
function openGuiNow()
 
  if hasPhone() then
    
    GiveWeaponToPed(PlayerPedId(), 0xA2719263, 0, 0, 1)
    guiEnabled = true
      SetCustomNuiFocus(false,false)
      SetCustomNuiFocus(true,true)
    TriggerServerEvent("websitesList")

    local isREAgent = false
    if isRealEstateAgent() then
      isREAgent = true
    end

    local device = false
    if hasDevice() then
      device = true
    end

    local decrypt = false
    if hasDecrypt() then
      decrypt = true
    end

    local decrypt2 = false
    if hasDecrypt2() then
      decrypt2 = true
    end

    local trucker = true
    -- if hasTrucker() then
    --   trucker = true
    -- end

    SendNUIMessage({openPhone = true, hasDevice = device, hasDecrypt = decrypt, hasDecrypt2 = decrypt2,hasTrucker = trucker, isRealEstateAgent = isREAgent, playerId = GetPlayerServerId(PlayerId())})

    TriggerEvent('phoneEnabled',true)
    TriggerEvent('animation:sms',true)

        --TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_TIME_OF_DEATH", 0, 1)
        
    -- If this is the first time we've opened the phone, load all contacts
  
    lstContacts = {}
    TriggerServerEvent('phone:getContacts')
    doTimeUpdate()
  else
    closeGui()
    if not exports["isPed"]:isPed("disabled") then
      TriggerEvent("DoLongHudText","You do not have a phone.",2)
    else
      TriggerEvent("DoLongHudText","You cannot use your phone right now.",2)
    end
  end
  recentopen = false
end

function openGui()

  if recentopen then
    return
  end
  if hasPhone() then
    GiveWeaponToPed(PlayerPedId(), 0xA2719263, 0, 0, 1)
    guiEnabled = true
      SetCustomNuiFocus(false,false)
      SetCustomNuiFocus(true,true)
    TriggerServerEvent("websitesList")

    local isREAgent = false
    if isRealEstateAgent() then
      isREAgent = true
    end

    local device = false
    if hasDevice() then
      device = true
    end

    local decrypt = false
    if hasDecrypt() then
      decrypt = true
    end

    local decrypt2 = false
    if hasDecrypt2() then
      decrypt2 = true
    end

    local trucker = false
    if hasTrucker() then
      trucker = true
    end

    SendNUIMessage({openPhone = true, hasDevice = device, hasDecrypt = decrypt, hasDecrypt2 = decrypt2,hasTrucker = trucker, isRealEstateAgent = isREAgent, playerId = GetPlayerServerId(PlayerId())})

    TriggerEvent('phoneEnabled',true)
    TriggerEvent('animation:sms',true)

        --TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_TIME_OF_DEATH", 0, 1)
        
    -- If this is the first time we've opened the phone, load all contacts
    
    lstContacts = {}
    TriggerServerEvent('phone:getContacts')
    doTimeUpdate()
  else
    closeGui()
    if not exports["isPed"]:isPed("disabled") then
      TriggerEvent("DoLongHudText","You do not have a phone.",2)
    else
      TriggerEvent("DoLongHudText","You cannot use your phone right now.",2)
    end
  end
  Citizen.Wait(3000)
  recentopen = false
end

RegisterNUICallback('btnPagerType', function(data, cb)
  TriggerServerEvent("secondaryjob:ServerReturnDate")
end)
local jobnames = {
  ["taxi"] = "Taxi Driver",
  ["towtruck"] = "Tow Truck Driver",
  ["trucker"] = "Delivery Driver",
}

RegisterNUICallback('newPostSubmit', function(data, cb)

  local myjob = exports["isPed"]:isPed("myjob")
  if myjob ~= "taxi" and myjob ~= "towtruck" and myjob ~= "trucker" then
    TriggerServerEvent('phone:updatePhoneJob', data.advert)
  else
    TriggerServerEvent('phone:updatePhoneJob', jobnames[myjob] .. " | " .. data.advert)
    TriggerEvent("DoLongHudText","You are already listed as a " .. myjob)
  end
  
end)

RegisterNUICallback('deleteYP', function()
  print('here')
  TriggerServerEvent('phone:deleteYP')
end)

RegisterNetEvent("yellowPages:retrieveLawyersOnline")
AddEventHandler("yellowPages:retrieveLawyersOnline", function()
  local isFound = false
  TriggerEvent('chatMessage', "", {0, 0, 255}, "Searching for a lawyer...")
  for i = 1, #YellowPageArray do
    local job = string.lower(YellowPageArray[tonumber(i)].job)
    if string.find(job, 'attorney') or string.find(job, 'lawyer') or string.find(job, 'public defender') then
      isFound = true
      TriggerEvent('chatMessage', "", {0, 0, 255}, "⚖️ " .. YellowPageArray[i].name .. " ☎️ " .. YellowPageArray[i].phonenumber)
    end
  end
  if not isFound then
    TriggerEvent('chatMessage', "", {255, 255, 255}, "There are no lawyers available right now. 😢")
  end
end)

RegisterNetEvent('YPUpdatePhone')
AddEventHandler('YPUpdatePhone', function()

  lstnotifications = {}

  for i = 1, #YellowPageArray do
      lstnotifications[#lstnotifications + 1] = {
        id = tonumber(i),
        name = YellowPageArray[tonumber(i)].name,
        message = YellowPageArray[tonumber(i)].job,
        phoneNumber = YellowPageArray[tonumber(i)].phonenumber
      }
  end
  SendNUIMessage({openSection = "notificationsYP", list = lstnotifications})
end)

local closeOtherNUI = function()
  TriggerEvent("closeInventoryGui")
  TriggerEvent("menu:menuexit")
  TriggerEvent("chat:close")
  TriggerEvent("clothing:close")
  TriggerEvent("mdt:close")
  TriggerEvent("Notepad:close")
end

-- Close Gui and disable NUI
function closeGui()
  closeOtherNUI()
    SetCustomNuiFocus(false,false)
  SendNUIMessage({openPhone = false})
  guiEnabled = false
  TriggerEvent('animation:sms',false)
  TriggerEvent('phoneEnabled',false)
  recentopen = true
  Citizen.Wait(3000)
  recentopen = false
  insideDelivers = false
end

function closeGui2()
  closeOtherNUI()
    SetCustomNuiFocus(false,false)
  SendNUIMessage({openPhone = false})
  guiEnabled = false
  recentopen = true
  Citizen.Wait(3000)
  recentopen = false  
end
local mousenumbers = {
  [1] = 1,
  [2] = 2,
  [3] = 3, 
  [4] = 4, 
  [5] = 5, 
  [6] = 6, 
  [7] = 12, 
  [8] = 13, 
  [9] = 66, 
  [10] = 67, 
  [11] = 95, 
  [12] = 96,   
  [13] = 97,   
  [14] = 98,
  [15] = 169,
   [16] = 170,
}

local currentMap = {}
local customMaps = {}
local dst = 30.0
local creatingMap = false
local SetBlips = {}
local particleList = {}
local currentRaces = {}
local JoinedRaces = {}
local racing = false
local racesStarted = 0
local mylastid = "NA"

-- Disable controls while GUI open
Citizen.CreateThread(function()
  local focus = true
  
  while true do

    if guiEnabled then
      DisableControlAction(0, 1, guiEnabled) -- LookLeftRight
      DisableControlAction(0, 2, guiEnabled) -- LookUpDown
      DisableControlAction(0, 14, guiEnabled) -- INPUT_WEAPON_WHEEL_NEXT
      DisableControlAction(0, 15, guiEnabled) -- INPUT_WEAPON_WHEEL_PREV
      DisableControlAction(0, 16, guiEnabled) -- INPUT_SELECT_NEXT_WEAPON
      DisableControlAction(0, 17, guiEnabled) -- INPUT_SELECT_PREV_WEAPON
      DisableControlAction(0, 99, guiEnabled) -- INPUT_VEH_SELECT_NEXT_WEAPON
      DisableControlAction(0, 100, guiEnabled) -- INPUT_VEH_SELECT_PREV_WEAPON
      DisableControlAction(0, 115, guiEnabled) -- INPUT_VEH_FLY_SELECT_NEXT_WEAPON
      DisableControlAction(0, 116, guiEnabled) -- INPUT_VEH_FLY_SELECT_PREV_WEAPON
      DisableControlAction(0, 142, guiEnabled) -- MeleeAttackAlternate
      DisableControlAction(0, 106, guiEnabled) -- VehicleMouseControlOverride
      if IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
        SendNUIMessage({type = "click"})
      end

    else
      mousemovement = 0
    end

    if selfieMode then
        if IsControlJustPressed(0, 177) then
          selfieMode = false
          DestroyMobilePhone()
          CellCamActivate(false, false)
        end
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(19)
        HideHudAndRadarThisFrame()
    else
      selfieMode = false
      DestroyMobilePhone()
      CellCamActivate(false, false)
    end

    if creatingMap then

      local plycoords = GetEntityCoords(GetPlayerPed(-1))

      DrawMarker(27,plycoords.x,plycoords.y,plycoords.z,0,0,0,0,0,0,dst,dst,0.3001,255,255,255,255,0,0,0,0)
      
      if #currentMap == 0 then
        DrawText3Ds(plycoords.x,plycoords.y,plycoords.z,"[E] to add start point, up/down for size, phone to save or cancel.")
      else
        DrawText3Ds(plycoords.x,plycoords.y,plycoords.z,"[E] to add check point, up/down for size, phone to save or cancel.")
      end

      if IsControlPressed(0,27) then
        dst = dst + 1
        if dst > 60.0 then
          dst = 60.0
        end
      end

      if IsControlPressed(0,173) then
        dst = dst - 1
        if dst < 4 then
          dst = 3.0
        end
      end

      if IsControlJustReleased(0,38) then
        if (IsControlPressed(0,21)) then --stop checkpoint adding when running.
          PopLastCheckpoint()
        else
          AddCheckPoint()
        end
        Wait(1000)
      end

    end
    Citizen.Wait(1)
  end
end)

function StartMapCreation()
  currentMap = {}
  dst = 30.0;
  creatingMap = true
end

function CancelMap()
  -- get distance here between checkpoints
  creatingMap = false
end

function ClearBlips()
  for i = 1, #SetBlips do
    RemoveBlip(SetBlips[i])
  end
  SetBlips = {}
end

function AddCheckPoint()
  loadCheckpointModels()
  local plycoords = GetEntityCoords(GetPlayerPed(-1))
  local ballsdick = dst/2
  local fx,fy,fz = table.unpack(GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1),  ballsdick, 0.0, -0.25))

  local fx2,fy2,fz2 = table.unpack(GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0 - ballsdick, 0.0, -0.25))
  
  addCheckpointMarker(vector3(fx,fy,fz), vector3(fx2,fy2,fz2))

  local start = false

  if #currentMap == 0 then
    start = true
  end

  local checkcounter = #currentMap + 1
  currentMap[checkcounter] = { 
    ["flare1x"] = FUCKK(fx), ["flare1y"] = FUCKK(fy), ["flare1z"] = FUCKK(fz),
    ["flare2x"] = FUCKK(fx2), ["flare2y"] = FUCKK(fy2), ["flare2z"] = FUCKK(fz2),
    ["x"] = FUCKK(plycoords.x),  ["y"] = FUCKK(plycoords.y), ["z"] = FUCKK(plycoords.z-1.1), ["start"] = start, ["dist"] = ballsdick, 
  }

  local key = #SetBlips+1
  SetBlips[key] = AddBlipForCoord(plycoords.x,plycoords.y,plycoords.z)
  SetBlipAsFriendly(SetBlips[key], true)
  SetBlipSprite(SetBlips[key], 1)
  ShowNumberOnBlip(SetBlips[key], key)
  BeginTextCommandSetBlipName("STRING");
  AddTextComponentString(tostring("Checkpoint " .. key))
  EndTextCommandSetBlipName(SetBlips[key])

end

local checkpointMarkers = {}
local isModelsLoaded = false
function loadCheckpointModels()
  local models = {}
  models[1] = "prop_offroad_tyres02"
  models[2] = "prop_beachflag_01"
  for i = 1, #models do
    local checkpointModel = GetHashKey(models[i])
    RequestModel(checkpointModel)
    while not HasModelLoaded(checkpointModel) do
      Citizen.Wait(1)
    end
  end
  isModelsLoaded = true
end

function addCheckpointMarker(leftMarker, rightMarker)
  local model = #checkpointMarkers == 0 and 'prop_beachflag_01' or 'prop_offroad_tyres02'

  local checkpointLeft = CreateObject(GetHashKey(model), leftMarker, false, false, false)
  local checkpointRight = CreateObject(GetHashKey(model), rightMarker, false, false, false)
  checkpointMarkers[#checkpointMarkers+1] = {
    left = checkpointLeft,
    right = checkpointRight
  }
  PlaceObjectOnGroundProperly(checkpointLeft)
  SetEntityAsMissionEntity(checkpointLeft)
  PlaceObjectOnGroundProperly(checkpointRight)
  SetEntityAsMissionEntity(checkpointRight)
end

function LoadMapBlips(id, reverseTrack, laps)
  print('loading map blips')
  local id = tostring(id)
  ClearBlips()
  loadCheckpointModels()
  print('id : ',id)
  print(json.encode(customMaps))
  print(json.encode(customMaps[id]))
  print(json.encode(customMaps[id].checkPoints))

  if(customMaps[id].checkPoints ~= nil) then
    print('checkpoints are not null')
    local checkpoints = customMaps[id].checkPoints
    if reverseTrack then
      local newCheckpoints = {}
      local count = 1
      for i=#checkpoints, 1, -1 do
        newCheckpoints[count] = checkpoints[i]
        count = count + 1
      end
      if laps ~= 0 then
        table.insert(newCheckpoints, 1, checkpoints[1])
        newCheckpoints[#newCheckpoints] = nil
      end
      checkpoints = newCheckpoints
    end

    for mId, map in pairs(checkpoints) do
      local key = #SetBlips+1
      SetBlips[key] = AddBlipForCoord(map["x"],map["y"],map["z"])
      SetBlipAsFriendly(SetBlips[key], true)
      SetBlipAsShortRange(SetBlips[key], true)
      SetBlipSprite(SetBlips[key], 1)
      ShowNumberOnBlip(SetBlips[key], key)
      BeginTextCommandSetBlipName("STRING");
      AddTextComponentString(tostring("Checkpoint " .. key))
      EndTextCommandSetBlipName(SetBlips[key])

      addCheckpointMarker(vector3(map["flare1x"], map["flare1y"], map["flare1z"]), vector3(map["flare2x"], map["flare2y"], map["flare2z"]))
    end
  end
end

function PopLastCheckpoint()
  if #currentMap > 1 then
    local lastCheckpoint = #currentMap
    SetEntityAsNoLongerNeeded(checkpointMarkers[lastCheckpoint].left)
    DeleteObject(checkpointMarkers[lastCheckpoint].left)
    SetEntityAsNoLongerNeeded(checkpointMarkers[lastCheckpoint].right)
    DeleteObject(checkpointMarkers[lastCheckpoint].right)
    RemoveBlip(SetBlips[lastCheckpoint])
    table.remove(checkpointMarkers)
    table.remove(currentMap)
    table.remove(SetBlips)
  end
end

function ShowText(text)
  TriggerEvent("DoLongHudText",text)
end

function StartEvent(map,laps,counter,reverseTrack,raceName, startTime, mapCreator, mapDistance, mapDescription)

  local map = tostring(map)
  local laps = tonumber(laps)
  local counter = tonumber(counter)
  local mapCreator = tostring(mapCreator)
  local mapDistance = tonumber(mapDistance)
  local mapDescription = tostring(mapDescription)
  local reverseTrack = reverseTrack

  if map == 0 then
    ShowText("Pick a map or use the old racing system.")
    return
  end

  local mapCheckpoints = customMaps[map]["checkPoints"]
  local checkPointIndex = 1
  if reverseTrack and laps == 0 then
    checkPointIndex = #mapCheckpoints
  end

  

  local ped = GetPlayerPed(-1)
  local plyCoords = GetEntityCoords(ped)
  local dist = Vdist(mapCheckpoints[checkPointIndex]["x"],mapCheckpoints[checkPointIndex]["y"],mapCheckpoints[checkPointIndex]["z"], plyCoords.x,plyCoords.y,plyCoords.z)

  if dist > 40.0 then
    ShowText("You are too far away!")
    return
  end

  print(json.encode(customMaps[map]))
  ShowText("Race Starting on " .. customMaps[map]["track_name"] .. " with " .. laps .. " laps in " .. counter .. " seconds!")
  racesStarted = racesStarted + 1
  local cid = exports["isPed"]:isPed("cid")
  local uniqueid = cid .. "-" .. racesStarted

  

  local s1, s2 = GetStreetNameAtCoord(mapCheckpoints[checkPointIndex].x, mapCheckpoints[checkPointIndex].y, mapCheckpoints[checkPointIndex].z)
  local street1 = GetStreetNameFromHashKey(s1)
  zone = tostring(GetNameOfZone(mapCheckpoints[checkPointIndex].x, mapCheckpoints[checkPointIndex].y, mapCheckpoints[checkPointIndex].z))
  local playerStreetsLocation = GetLabelText(zone)
  local dir = getCardinalDirectionFromHeading()
  local street1 = street1 .. ", " .. playerStreetsLocation
  local street2 = GetStreetNameFromHashKey(s2) .. " " .. dir
  TriggerServerEvent("racing-global-race",map, laps, counter, reverseTrack, uniqueid, cid, raceName, startTime, mapCreator, mapDistance, mapDescription, street1, street2)
end

function hudUpdate(pHudState, pHudData)
  pHudState = pHudState or 'finished'
  pHudData = pHudData or '{}'
  SendNUIMessage({
    openSection = "racing:hud:update",
    hudState = pHudState,
    hudData = pHudData
  })
end

function RunRace(identifier)

  print(json.encode(currentRaces))
  local map = currentRaces[identifier][identifier].map
  print(json.encode(map))
  local laps = currentRaces[identifier][identifier].laps
  local counter = currentRaces[identifier][identifier].counter
  local sprint = false

  if laps == 0 then
    laps = 1
    sprint = true
  end
  local myLap = 0
  
  print(json.encode(customMaps))
  print(json.encode(customMaps[map]))
  local checkpoints = #customMaps[map]["checkPoints"]
  local mycheckpoint = 1

  local ped = GetPlayerPed(-1)

  SetBlipColour(SetBlips[1], 3)
  SetBlipScale(SetBlips[1], 1.6)

  TriggerEvent("DoLongHudText","Race Starts in 3",14)
  PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
  Citizen.Wait(1000)
  TriggerEvent("DoLongHudText","Race Starts in 2",14)
  PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
  Citizen.Wait(1000)
  TriggerEvent("DoLongHudText","Race Starts in 1",14)
  PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
  Citizen.Wait(1000)
  PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
  TriggerEvent("DoLongHudText","GO!",14)
  hudUpdate('start', {
    isSprint = sprint,
    maxLaps = laps,
    maxCheckpoints = checkpoints
  })

  local tempCheckpoints = customMaps[map].checkPoints
  if currentRaces[identifier].reverseTrack then
    local newCheckpoints = {}
    local count = 1
    for i=#tempCheckpoints, 1, -1 do
      newCheckpoints[count] = tempCheckpoints[i]
      count = count + 1
    end
    if not sprint then
      table.insert(newCheckpoints, 1, tempCheckpoints[1])
      newCheckpoints[#newCheckpoints] = nil
    end
    tempCheckpoints = newCheckpoints
  end

  if tempCheckpoints ~= nil then

    --for index, checkpoint in pairs(tempCheckpoints) do
      --loadCheckpointModels()
      --for index, map in pairs(racers) do
      --    addCheckpointMarker(vector3(map["flare1x"], map["flare1y"], map["flare1z"]), vector3(map["flare2x"], map["flare2y"], map["flare2z"]))
      --end

      --/
      --local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
      --print(json.encode(waypointCoords))
      --local retval, coords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1)
      --local key = #SetBlips+1
      --checkpoint.blip = AddBlipForCoord(checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z)
      --SetBlipAsFriendly(checkpoint.blip, true)
      --SetBlipSprite(checkpoint.blip, 1)
      --ShowNumberOnBlip(checkpoint.blip, index)
      --BeginTextCommandSetBlipName("STRING");
      --AddTextComponentString(tostring("Checkpoint " ..index))
      --EndTextCommandSetBlipName(checkpoint.blip)
      --/
    --end
  end

  while myLap < laps+1 and racing do

    Wait(1)
    local plyCoords = GetEntityCoords(ped)
    if ( Vdist(tempCheckpoints[mycheckpoint]["x"],tempCheckpoints[mycheckpoint]["y"],tempCheckpoints[mycheckpoint]["z"], plyCoords.x,plyCoords.y,plyCoords.z) ) < tempCheckpoints[mycheckpoint]["dist"] then

      SetBlipColour(SetBlips[mycheckpoint], 3)
      SetBlipScale(SetBlips[mycheckpoint], 1.0)

      
      --PlaySound(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
      mycheckpoint = mycheckpoint + 1

      SetBlipColour(SetBlips[mycheckpoint], 2)
      SetBlipScale(SetBlips[mycheckpoint], 1.6)
      SetBlipAsShortRange(SetBlips[mycheckpoint-1], true)
      SetBlipAsShortRange(SetBlips[mycheckpoint], false)



      if mycheckpoint > checkpoints then
        mycheckpoint = 1
      end

      SetNewWaypoint(tempCheckpoints[mycheckpoint]["x"],tempCheckpoints[mycheckpoint]["y"])

      if not sprint and mycheckpoint == 1 then

        SetBlipColour(SetBlips[1], 2)
        SetBlipScale(SetBlips[1], 1.6)

      end

      if not sprint and mycheckpoint == 2 then
        myLap = myLap + 1

        -- Uncomment these lines to make the checkpoints re-draw on each lap
        --ClearBlips()
        --RemoveCheckpoints()
        --LoadMapBlips(map)
        SetBlipColour(SetBlips[1], 3)
        SetBlipScale(SetBlips[1], 1.0)
        SetBlipColour(SetBlips[2], 2)
        SetBlipScale(SetBlips[2], 1.6)
      elseif sprint and mycheckpoint == 1 then
        myLap = myLap + 2
      end

      hudUpdate('update', {
        curLap = myLap,
        curCheckpoint = (mycheckpoint-1)
      })
    end
  end

  hudUpdate('finished', {
    eventId = identifier
  })

  PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
  TriggerEvent("DoLongHudText","You have finished!",14)
  Wait(10000)
  racing = false
  hudUpdate('clear')
  ClearBlips()
  RemoveCheckpoints()
end

function EndRace()
  ClearBlips()
  RemoveCheckpoints()
end

function RemoveCheckpoints()
  for i = 1, #checkpointMarkers do
    SetEntityAsNoLongerNeeded(checkpointMarkers[i].left)
    DeleteObject(checkpointMarkers[i].left)
    SetEntityAsNoLongerNeeded(checkpointMarkers[i].right)
    DeleteObject(checkpointMarkers[i].right)
    checkpointMarkers[i] = nil
  end
end

function FUCKK(num)
  local new = math.ceil(num*100)
  new = new / 100
  return new
end

function SaveMap(name,description)
  -- get distance here between checkpoints

  local distanceMap = 0.0
  for i = 1, #currentMap do
    if i == #currentMap then
      distanceMap = Vdist(currentMap[i]["x"],currentMap[i]["y"],currentMap[i]["z"], currentMap[1]["x"],currentMap[1]["y"],currentMap[1]["z"]) + distanceMap
    else
      distanceMap = Vdist(currentMap[i]["x"],currentMap[i]["y"],currentMap[i]["z"], currentMap[i+1]["x"],currentMap[i+1]["y"],currentMap[i+1]["z"]) + distanceMap
    end
  end
  distanceMap = math.ceil(distanceMap)

  if #currentMap > 1 then
    TriggerEvent("DoLongHudText","The map is being processed and should be available shortly.",2)
    TriggerServerEvent("racing-save-map",currentMap,name,description,distanceMap)
  else
    TriggerEvent("DoLongHudText","Failed due to lack of checkpoints",2)
  end
  currentMap = {}
  creatingMap = false
end

RegisterNUICallback('racing:events:list', function()
  local rank = exports["isPed"]:GroupRank("ug_racing")
  SendNUIMessage({
    openSection = "racing:events:list",
      races = currentRaces,
      canMakeMap = (rank >= 4 and true or false)
    });
    TriggerServerEvent("racing-retreive-maps")
end)

RegisterNUICallback('racing:events:highscore', function()
  TriggerServerEvent("racing-retreive-maps")
  Wait(300)
  local highScoreObject = {}
  for k,v in pairs(customMaps) do
    highScoreObject[k] = {
      fastestLap = v.fastest_lap,
      fastestName = v.fastest_name,
      fastestSprint = v.fastest_sprint,
      fastestSprintName = v.fastest_sprint_name,
      map = v.track_name,
      noOfRaces = v.races,
      mapDistance = v.distance
    }
  end

  SendNUIMessage({
    openSection = "racing:events:highscore",
    highScoreList = highScoreObject
  });
end)

-- Callback when setting up new Event
RegisterNUICallback('racing:event:setup', function()
  TriggerServerEvent("racing-build-maps")
end)

-- Fix
RegisterNUICallback('racing:event:leave', function()
  hudUpdate('clear')
  ClearBlips()
  RemoveCheckpoints()
  racing = false
end)

-- Fix
RegisterNUICallback('racing:event:join', function(data)
  RemoveCheckpoints()
  local id = data.identifier
  local ped = GetPlayerPed(-1)
  local plyCoords = GetEntityCoords(ped)

  print(json.encode(data))
  print('id : ', id)
  print('custom maps : ')
  print(json.encode(customMaps))
  print('my map : ')
  print(json.encode(currentRaces[id][id]["map"]))
  print(json.encode(currentRaces[id]["map"]))

  local mapCheckpoints = customMaps[currentRaces[id][id]["map"]]["checkPoints"]

  print("mapCheckpoints")
  print(json.encode(mapCheckpoints))
  print(json.encode(mapCheckpoints[checkPointIndex]))

  local checkPointIndex = 1

  print(currentRaces[id][id]["reverseTrack"])
  print(currentRaces[id][id]["laps"])

  if currentRaces[id][id]["reverseTrack"] and currentRaces[id][id]["laps"] == 0 then
    checkPointIndex = #mapCheckpoints
  end

  print("checkPointIndex : ", checkPointIndex)
  print('JoinedRaces : ', json.encode(JoinedRaces))
  print("racing  : ", racing)
  print('race open : ', currentRaces[id][id]["open"])
  if Vdist(mapCheckpoints[checkPointIndex]["x"], mapCheckpoints[checkPointIndex]["y"], mapCheckpoints[checkPointIndex]["z"],plyCoords.x,plyCoords.y,plyCoords.z) < 40 then
    -- IF the race is OPEN and you are not in the race and youre not racing
    --console.log(not JoinedRaces[id])
    if currentRaces[id][id]["open"] and (JoinedRaces[id] == nil or not JoinedRaces[id]) and not racing then
      print(' the race is OPEN and you are not in the race and youre not racing')
      racing = true

      local myJob = exports["isPed"]:isPed("myJob")
      if myJob == "towtruck" then
        TriggerServerEvent("jobssystem:jobs", "unemployed")
        Wait(1000)
        closeGui()
      end
      JoinedRaces[id] = true
      TriggerServerEvent("racing-join-race",id)
      hudUpdate('starting')
      ShowText("Joining Race!")
      LoadMapBlips(currentRaces[id][id]["map"], currentRaces[id][id]["reverseTrack"], currentRaces[id][id]["laps"])
    else
      -- IF youre in this race and youre not racing
      print("racing  : ", racing)
      print('has joined race ', id, ' ', JoinedRaces[id])
      if (JoinedRaces[id] and not racing) then
        racing = true
        hudUpdate('starting')
      else
        ShowText("This race is closed or you are already in it!")
      end
    end
  else
    ShowText("You are too far away!")
  end
end)

-- Fix
RegisterNUICallback('racing:event:start', function(data)
  StartEvent(data.raceMap, data.raceLaps, data.raceCountdown, data.reverseTrack, data.raceName, data.raceStartTime, data.mapCreator, data.mapDistance, data.mapDescription)
  Wait(500)
  SendNUIMessage({
    openSection = "racing:events:list",
    races = currentRaces
  });
end)

-- Fix this
RegisterNUICallback('race:completed', function(data)
  JoinedRaces[data.identifier] = nil
  TriggerServerEvent("race:completed2",data.fastestlap, data.overall, data.sprint, data.identifier)
  EndRace()
end)

-- Racing:Map
RegisterNUICallback('racing:map:create', function()
  StartMapCreation()
end)

RegisterNUICallback('racing:map:load', function(data)
  ClearBlips()
  RemoveCheckpoints()
  if(data.id ~= nil) then
    LoadMapBlips(data.id)
  end
end)

RegisterNUICallback('racing:map:delete', function(data)
  ClearBlips()
  RemoveCheckpoints()
  if data.id ~= "0" then
    TriggerServerEvent("racing-map-delete",customMaps[tonumber(data.id)]["dbid"])
  end
end)

RegisterNUICallback('racing:map:removeBlips', function()
  EndRace()
end)

RegisterNUICallback('racing:map:cancel', function()
  EndRace()
  CancelMap()
end)

RegisterNUICallback('racing:map:save', function(data)
  EndRace()
  SaveMap(data.name,data.desc)
end)

RegisterNetEvent('racing:data:set')
AddEventHandler('racing:data:set', function(data)
  print('racing:data:set', json.encode(data))
  print("////////////////////////////////////////////////////////")
  if(data.event == "map") then
    if (data.eventId ~= -1) then
      customMaps[data.eventId] = data.data
    else
      customMaps = data.data
      if(data.subEvent == nil or data.subEvent ~= "noNUI") then
        SendNUIMessage({
          openSection = 'racing-start',
          maps = customMaps
        })
      end
    end
  elseif (data.event == "event") then
    if (data.eventId ~= -1) then
      currentRaces[data.eventId] = data.data
      print('racing ------------>', racing)
      print(data.subEvent)
      print( json.encode(JoinedRaces[data.eventId]))
      if JoinedRaces[data.eventId] and racing and data.subEvent == "close" then
        print('in if joinedrces')
        print( json.encode(JoinedRaces[data.eventId]))
        RunRace(data.eventId)
      end
      SendNUIMessage({
        openSection = "racing:event:update",
        eventId = data.eventId,
        raceData = currentRaces[data.eventId],
        playerRacing = racing
      })
    else
      currentRaces = data.data
      SendNUIMessage({
        openSection = "racing:event:update",
        raceData = currentRaces
      })
    end
  end
end)

RegisterNetEvent('racing:clearFinishedRaces')
AddEventHandler('racing:clearFinishedRaces', function(id)
  if(JoinedRaces[id] ~= nil) then
    JoinedRaces[id] = nil
    ClearBlips()
    RemoveCheckpoints()
  end
end)










































-- Opens our phone
RegisterNetEvent('phoneGui2')
AddEventHandler('phoneGui2', function()
  openGui()
end)

-- NUI Callback Methods
RegisterNUICallback('close', function(data, cb)
  closeGui()
  cb('ok')
end)

RegisterNetEvent('phone:close')
AddEventHandler('phone:close', function(number, message)
  closeGui()

end)




RegisterNUICallback('2ndRemove', function(data, cb)
  TriggerEvent("secondaryjob:removejob")
  cb('ok')
end)

RegisterNUICallback('2ndWeedSt', function(data, cb)
  TriggerEvent("secondaryjob:weedStreet")
  cb('ok')
end)
RegisterNUICallback('2ndWeedHigh', function(data, cb)
  TriggerEvent("secondaryjob:weedHigh")
  cb('ok')
end)
RegisterNUICallback('2ndMethSt', function(data, cb)
  TriggerEvent("secondaryjob:cocaineStreet")
  cb('ok')
end)
RegisterNUICallback('2ndMethHigh', function(data, cb)
  TriggerEvent("secondaryjob:cocaineHigh")
  cb('ok')
end)
RegisterNUICallback('2ndGunSt', function(data, cb)
  TriggerEvent("secondaryjob:gunStreet")
  cb('ok')
end)
RegisterNUICallback('2ndGunHigh', function(data, cb)
  TriggerEvent("secondaryjob:gunHigh")
  cb('ok')
end)
RegisterNUICallback('2ndGunSmith', function(data, cb)
  local rank = exports["isPed"]:GroupRank("carpet_factory")
  if rank > 0 then
    TriggerEvent("secondaryjob:gunSmith")
  else
    TriggerEvent("DoLongHudText","This does not seem to work.")
  end
  cb('ok')
end)
RegisterNUICallback('2ndMoneyCleaner', function(data, cb)
  TriggerEvent("secondaryjob:moneyCleaner")
  cb('ok')
end)
RegisterNUICallback('2ndMoneySt', function(data, cb)
  TriggerEvent("secondaryjob:moneyStreet")
  cb('ok')
end)
RegisterNUICallback('2ndMoneyHigh', function(data, cb)
  TriggerEvent("secondaryjob:moneyHigh")
  cb('ok')
end)

-- phone button EVH




RegisterNUICallback('btnStances', function()
  closeGui()
  TriggerEvent("openSubMenu","Anim Sets")
end)

RegisterNUICallback('loadGPS', function()
  TriggerEvent("GPSLocations")
end)

RegisterNUICallback('btnProps', function()
  closeGui()
  TriggerEvent("openSubMenu","Prop Attach")
end)


RegisterNUICallback('btnShowId', function()
  closeGui()
  TriggerEvent("checkmyId")
  loadAnimDict('friends@laf@ig_5')
  TaskPlayAnim(PlayerPedId(),'friends@laf@ig_5', 'nephew',5.0, 1.0, 5.0, 48, 0.0, 0, 0, 0)

  
end)

RegisterNUICallback('btnEmotes', function()
  closeGui()
  TriggerEvent("emotes:OpenMenu")
end)

RegisterNUICallback('btnPagerToggle', function()
  TriggerEvent("togglePager")
end)

RegisterNUICallback('removeHouseKey', function(data, cb)
  TriggerEvent("houses:removeHouseKey", data.targetId)
  cb('ok')
end)

RegisterNUICallback('retrieveHouseKeys', function(data, cb)
  TriggerEvent("houses:retrieveHouseKeys")
  cb('ok')
end)

RegisterNUICallback('btnCarKey', function()
  closeGui()
  TriggerEvent("keys:give")
end)

RegisterNUICallback('btnHouseKey', function()
  closeGui()
  TriggerEvent("apart:giveKey")
end)










-- SMS Callbacks
RegisterNUICallback('messages', function(data, cb)
  loading()
  TriggerServerEvent('phone:getSMS')
  print('neek')
  cb('ok')
end)

RegisterNetEvent('phone:clientGetMessagesBetweenParties')
AddEventHandler('phone:clientGetMessagesBetweenParties', function(messages, displayName, clientNumber)
  SendNUIMessage({openSection = "messageRead", messages = messages, displayName = displayName, clientNumber = clientNumber})
end)

--$.post...
RegisterNUICallback('messageRead', function(data, cb)
  TriggerServerEvent('phone:serverGetMessagesBetweenParties', data.sender, data.receiver, data.displayName)
  cb('ok')
end)

RegisterNUICallback('messageDelete', function(data, cb)
  TriggerServerEvent('phone:removeSMS', data.id, data.number)
  cb('ok')
end)

RegisterNUICallback('newMessage', function(data, cb)
  SendNUIMessage({openSection = "newMessage"})
  cb('ok')
end)





RegisterNUICallback('messageReply', function(data, cb)
  SendNUIMessage({openSection = "newMessageReply", number = data.number})
  cb('ok')
end)

RegisterNUICallback('newMessageSubmit', function(data, cb)
  if not isDead then
    TriggerEvent('phone:sendSMS', tonumber(data.number), data.message)
    cb('ok')
  else
    TriggerEvent("DoLongHudText","You can not do this while injured.",2)
  end
end)

-- TODO: This
-- RegisterNetEvent("TokoVoip:UpVolume");
-- AddEventHandler("TokoVoip:UpVolume", setVolumeUp);

RegisterNetEvent('refreshYP')
AddEventHandler('refreshYP', function()
  if guiEnabled then
    TriggerServerEvent('getYP')
    Citizen.Wait(250)
    TriggerEvent('YPUpdatePhone')
  end
end)


-- Contact Callbacks
RegisterNUICallback('contacts', function(data, cb)
  TriggerServerEvent('phone:getSMSc')
  SendNUIMessage({openSection = "contacts"})
  cb('ok')
end)

RegisterNUICallback('newContact', function(data, cb)
  SendNUIMessage({openSection = "newContact"})
  cb('ok')
end)

RegisterNUICallback('newContactSubmit', function(data, cb)
  TriggerEvent('phone:addContact', data.name, tonumber(data.number))
  cb('ok')
end)

RegisterNUICallback('deleteContact', function(data, cb)
  TriggerServerEvent('phone:deleteContact', data.name, data.number)
  cb('ok')
end)

--call status 0 = no call, 1 = dialing, 2 = receiving call, 3 = in progresss
myID = 0
mySourceID = 0

mySourceHoldStatus = false
TriggerEvent('phone:setCallState', isNotInCall)
costCount = 1

RegisterNetEvent('animation:phonecallstart')
AddEventHandler('animation:phonecallstart', function()
  TriggerEvent("destroyPropPhone")
  TriggerEvent("incall",true)
  local lPed = PlayerPedId()
  RequestAnimDict("cellphone@")
  while not HasAnimDictLoaded("cellphone@") do
    Citizen.Wait(0)
  end
  local count = 0
  costCount = 1
  inPhone = false
  Citizen.Wait(200)
  ClearPedTasks(lPed)
  
  TriggerEvent("attachItemPhone","phone01")

  TriggerEvent("DoShortHudText", "[E] Toggles Call.",10)

  while callStatus ~= isNotInCall do

    if isDead then
      endCall()
    end


    if IsEntityPlayingAnim(lPed, "cellphone@", "cellphone_call_listen_base", 3) and not IsPedRagdoll(PlayerPedId()) then
      --ClearPedSecondaryTask(lPed)
    else 



      if IsPedRagdoll(PlayerPedId()) then
        Citizen.Wait(1000)
      end
      TaskPlayAnim(lPed, "cellphone@", "cellphone_call_listen_base", 1.0, 1.0, -1, 49, 0, 0, 0, 0)
    end
    Citizen.Wait(1)
    count = count + 1

    if AnonCall then
       local dPB = #(PhoneBooth - GetEntityCoords( PlayerPedId()))
       if dPB > 2.0 then
        TriggerEvent("DoShortHudText", "Moved Too Far.",10)
        endCall()
       end
    end



    if IsControlJustPressed(0, 38) then
      TriggerEvent("phone:holdToggle")
    end

    if onhold then
      if count == 800 then
         count = 0
         TriggerEvent("DoShortHudText", "Call On Hold.",10)
      end
    end

      --check if not unarmed
    local curw = GetSelectedPedWeapon(PlayerPedId())
    noweapon = `WEAPON_UNARMED`
    if noweapon ~= curw then
      SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    end

  end
  ClearPedTasks(lPed)
  TaskPlayAnim(lPed, "cellphone@", "cellphone_call_out", 2.0, 2.0, 800, 49, 0, 0, 0, 0)
  Citizen.Wait(700)
  TriggerEvent("destroyPropPhone")
  TriggerEvent("incall",false)
end)


RegisterNetEvent('pd:deathcheck')
AddEventHandler('pd:deathcheck', function()
  if not isDead then
    endCall()
    isDead = true
  else
    isDead = false
  end
end)

RegisterNetEvent('phone:makecall')
AddEventHandler('phone:makecall', function(pnumber)

  local pnumber = tonumber(pnumber)
  AnonCall = false
  if callStatus == isNotInCall and not isDead and hasPhone() then
    local dialingName = getContactName(pnumber)
    TriggerEvent('phone:setCallState', isDialing, dialingName)
    TriggerEvent("animation:phonecallstart")
    recentcalls[#recentcalls + 1] = { ["type"] = 2, ["number"] = pnumber, ["name"] = dialingName }
    TriggerServerEvent('phone:callContact', pnumber, true)
  else
    TriggerEvent("DoLongHudText","It appears you are already in a call, injured or with out a phone, please type /hangup to reset your calls.",2)
  end
end)



local PayPhoneHex = {
  [1] = 1158960338,
  [2] = -78626473,
  [3] = 1281992692,
  [4] = -1058868155,
  [5] = -429560270,
  [6] = -2103798695,
  [7] = 295857659,
}

function checkForPayPhone()
  for i = 1, #PayPhoneHex do
    local objFound = GetClosestObjectOfType( GetEntityCoords(PlayerPedId()), 5.0, PayPhoneHex[i], 0, 0, 0)
    if DoesEntityExist(objFound) then
      return true
    end
  end
  return false
end

RegisterNetEvent('phone:makepayphonecall')
AddEventHandler('phone:makepayphonecall', function(pnumber)

    if not checkForPayPhone() then
      TriggerEvent("DoLongHudText","You are not near a payphone.",2)
      return
    end

    PhoneBooth = GetEntityCoords( PlayerPedId() )
    AnonCall = true

    local pnumber = tonumber(pnumber)
    if callStatus == isNotInCall and not isDead then
      TriggerEvent('phone:setCallState', isDialing)
      TriggerEvent("animation:phonecallstart")
      TriggerEvent("InteractSound_CL:PlayOnOne","payphonestart",0.5)
      TriggerServerEvent('phone:callContact', pnumber, false)
    else
      TriggerEvent("DoLongHudText","It appears you are already in a call, injured or with out a phone, please type /hangup to reset your calls.",2)
    end

end)





RegisterNUICallback('callContact', function(data, cb)
  closeGui()
  AnonCall = false
  Wait(1500)
  if callStatus == isNotInCall and not isDead and hasPhone() then
    TriggerEvent('phone:setCallState', isDialing, data.name == "" and data.number or data.name)
    TriggerEvent("animation:phonecallstart")
    TriggerServerEvent('phone:callContact', data.number, true)
  else
    TriggerEvent("DoLongHudText","It appears you are already in a call, injured or with out a phone, please type /hangup to reset your calls.",2)
  end
  cb('ok')
end)

debugn = false
function t(trace)
  print(trace)
end

RegisterNetEvent('phone:failedCall')
AddEventHandler('phone:failedCall', function()
    t("Failed Call")
    endCall()
end)




RegisterNetEvent('phone:hangup')
AddEventHandler('phone:hangup', function(AnonCall)
    if AnonCall then
      t("Call Anon Hangup")
      endCall2()
    else
      t("Call Hangup")
      endCall()
    end
end)

RegisterNetEvent('phone:hangupcall')
AddEventHandler('phone:hangupcall', function()
    if AnonCall then
      t("Call Anon Hangup 2")
      endCall2()
    else
      t("Call Hangup 2")
      endCall()
    end
end)
RegisterNetEvent('phone:otherClientEndCall')
AddEventHandler('phone:otherClientEndCall', function()
    local playerId = GetPlayerFromServerId(mySourceID)

    if tonumber(mySourceID) ~= 0 then
      TriggerServerEvent("phone:EndCall",mySourceID,callid)
    end

    if tonumber(myID) ~= 0 then
      TriggerServerEvent("phone:EndCall",myID,callid)
    end 

    TriggerEvent("InteractSound_CL:PlayOnOne","demo",0.1)
    TriggerEvent("DoLongHudText","Your call was ended!",2)
    callid = 0
    myID = 0
    mySourceID = 0
    mySourceHoldStatus = false
    TriggerEvent('phone:setCallState', isNotInCall)
    onhold = false
    closeGui()
end)

RegisterNUICallback('btnAnswer', function()
    closeGui()
    TriggerEvent("phone:answercall")
end)
RegisterNUICallback('btnHangup', function()
    closeGui()
    TriggerEvent("phone:hangup")
end)

RegisterNetEvent('phone:answercall')
AddEventHandler('phone:answercall', function()
    if callStatus == isReceivingCall and not isDead then
    answerCall()
    TriggerEvent("animation:phonecallstart")
    TriggerEvent("DoLongHudText","You have answered a call.",1)
    callTimer = 0
  else
    TriggerEvent("DoLongHudText","You are not being called, injured, or you took too long.",2)
  end
end)

RegisterNetEvent('phone:initiateCall')
AddEventHandler('phone:initiateCall', function(srcID)
    TriggerEvent("DoLongHudText","You have started a call.",1)
    initiatingCall()
    if not AnonCall then
      TriggerEvent("InteractSound_CL:PlayOnOne","demo",0.1)
    end
end)

RegisterNetEvent('phone:callFullyInitiated')
AddEventHandler('phone:callFullyInitiated', function(srcID,sentSource)
 TriggerEvent("InteractSound_CL:PlayOnOne","demo",0.1)
  myID = srcID
  mySourceID = sentSource
  TriggerEvent('phone:setCallState', isCallInProgress)
  callTimer = 0

  --NetworkSetVoiceChannel(srcID+1)
  --NetworkSetTalkerProximity(0.0)
  
  TriggerEvent("phone:callactive")
end)
function drawTxt(x,y ,width,height,scale, text, r,g,b,a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end
RegisterNetEvent('phone:callactive')
AddEventHandler('phone:callactive', function()
    Citizen.Wait(100)
    local held1 = false
    local held2 = false
    while callStatus == isCallInProgress do
      local phoneString = ""
      Citizen.Wait(1)

      if onhold then
        phoneString = phoneString .. "They are on Hold | "
        if not held1 then
          TriggerEvent("DoLongHudText","You have put the caller on hold.",888)
          held1 = true
        end
      else
        phoneString = phoneString .. "Call Active | "
        if held1 then
          TriggerEvent("DoLongHudText","Your call is no longer on hold.",888)
          held1 = false
        end
      end

      if mySourceHoldStatus then
        phoneString = phoneString .. "You are on hold"
        if not held2 then
          TriggerEvent("DoLongHudText","You are on hold.",2)
          held2 = true
        end
      else
        phoneString = phoneString .. "Caller Active"
        if held2 then
          TriggerEvent("DoLongHudText","You are no longer on hold.",2)
          held2 = false
        end
      end
      drawTxt(0.97, 1.46, 1.0,1.0,0.33, phoneString, 255, 255, 255, 255)  -- INT: kmh
    end
end)


local callid = 0
RegisterNetEvent('phone:id')
AddEventHandler('phone:id', function(sentcallid)
  callid = sentcallid
end)

RegisterNetEvent('phone:setCallState')
AddEventHandler('phone:setCallState', function(pCallState, pCallInfo)
  callStatus = pCallState
  SendNUIMessage({
    openSection = 'callState',
    callState = pCallState,
    callInfo = pCallInfo
  })
end)

RegisterNetEvent('phone:receiveCall')
AddEventHandler('phone:receiveCall', function(phoneNumber, srcID, calledNumber)
  local callFrom = getContactName(calledNumber)
  recentcalls[#recentcalls + 1] = { ["type"] = 1, ["number"] = calledNumber, ["name"] = callFrom }

  if callStatus == isNotInCall then
    myID = 0
    mySourceID = srcID
    TriggerEvent('phone:setCallState', isReceivingCall, callFrom)

    receivingCall(callFrom) -- Send contact name if exists, if not send number
  else

    TriggerEvent("DoLongHudText","You are receiving a call from " .. callFrom .. " but are currently already in one, sending busy response.",2)
  end
end)
callTimer = 0
function initiatingCall()
  callTimer = 8

  TriggerEvent("DoLongHudText","You are making a call, please hold.",1)
  while (callTimer > 0 and callStatus == isDialing) do
    if AnonCall and callTimer < 7 then
      TriggerEvent("InteractSound_CL:PlayOnOne","payphoneringing",0.5)
    elseif not AnonCall then
      TriggerEvent("InteractSound_CL:PlayOnOne","cellcall",0.5)
    end
    
    Citizen.Wait(2500)
    callTimer = callTimer - 1
  end
  if callStatus == isDialing or callTimer == 0 then
    endCall()
  end
end

function receivingCall(callFrom)
  callTimer = 8
  while (callTimer > 0 and callStatus == isReceivingCall) do
    if hasPhone() then
      TriggerEvent("DoShortHudText","Call from: " .. callFrom .. " /answer or /hangup",10)
      if phoneNotifications then
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 2.0, 'cellcall', 0.5)
      end
    end
    Citizen.Wait(2300)
    callTimer = callTimer - 1
  end
  if callStatus ~= isCallInProgress then
    endCall()
  end
end

function answerCall()

    if mySourceID ~= 0 then

      --NetworkSetVoiceChannel(mySourceID+1)
      --NetworkSetTalkerProximity(0.0)

      TriggerServerEvent("phone:StartCallConfirmed",mySourceID)
      TriggerEvent('phone:setCallState', isCallInProgress)
      TriggerEvent("phone:callactive")
    end
end

function endCall()
  TriggerEvent("InteractSound_CL:PlayOnOne","demo",0.1)
  if tonumber(mySourceID) ~= 0 then
    TriggerServerEvent("phone:EndCall",mySourceID,callid)
  end

  if tonumber(myID) ~= 0 then
    TriggerServerEvent("phone:EndCall",myID,callid)
  end 

  myID = 0
  mySourceID = 0
  TriggerEvent('phone:setCallState', isNotInCall)
  onhold = false
  mySourceHoldStatus = false
  AnonCall = false
  callid = 0
  closeGui()
end

function endCall2()
  TriggerEvent("InteractSound_CL:PlayOnOne","payphoneend",0.1)
  if tonumber(mySourceID) ~= 0 then
    TriggerServerEvent("phone:EndCall",mySourceID,callid)
  end

  if tonumber(myID) ~= 0 then
    TriggerServerEvent("phone:EndCall",myID,callid)
  end 

  myID = 0
  mySourceID = 0
  TriggerEvent('phone:setCallState', isNotInCall)
  onhold = false
  mySourceHoldStatus = false
  AnonCall = false
  callid = 0
  closeGui()
  --[[ 
  NetworkSetTalkerProximity(1.0)
  Citizen.Wait(300)
  NetworkClearVoiceChannel()
  Citizen.Wait(300)
  NetworkSetTalkerProximity(18.0)
  ]]
end


RegisterNetEvent('phone:holdToggle')
AddEventHandler('phone:holdToggle', function()
  if myID == nil then
    myID = 0
  end
  if myID ~= 0 then
    if not onhold then
      TriggerEvent("DoShortHudText", "Call on hold.",10)
      onhold = true

      --[[  
      NetworkSetTalkerProximity(1.0)
      Citizen.Wait(300)
      NetworkClearVoiceChannel()
      Citizen.Wait(300)
      NetworkSetTalkerProximity(18.0)
      ]]

      TriggerServerEvent("OnHold:Server",mySourceID,true)
    else
      TriggerEvent("DoShortHudText", "No longer on hold.",10)
      TriggerServerEvent("OnHold:Server",mySourceID,false)
      onhold = false

      --NetworkSetVoiceChannel(myID+1)
      --NetworkSetTalkerProximity(0.0)
    end
  else

    if mySourceID ~= 0 then
      if not onhold then
        TriggerEvent("DoShortHudText", "Call on hold.",10)
        onhold = true

        --[[ 
        NetworkSetTalkerProximity(1.0)
        Citizen.Wait(300)
        NetworkClearVoiceChannel()
        Citizen.Wait(300)
        NetworkSetTalkerProximity(18.0)
        ]]

        TriggerServerEvent("OnHold:Server",mySourceID,true)
      else
        TriggerEvent("DoShortHudText", "No longer on hold.",10)
        TriggerServerEvent("OnHold:Server",mySourceID,false)
        onhold = false

        --NetworkSetVoiceChannel(mySourceID+1)
        --NetworkSetTalkerProximity(0.0)
      end
    end
  end
end)


RegisterNetEvent('OnHold:Client')
AddEventHandler('OnHold:Client', function(newHoldStatus,srcSent)
    mySourceHoldStatus = newHoldStatus
    if mySourceHoldStatus then
        local playerId = GetPlayerFromServerId(srcSent)
        
        TriggerEvent("DoLongHudText","You just got put on hold.")
    else
        if not onhold then
          local playerId = GetPlayerFromServerId(srcSent)
          
        end
        TriggerEvent("DoLongHudText","Your caller is back on the line.")
    end
end)


curNotifications = {}

RegisterNetEvent('phone:addnotification')
AddEventHandler('phone:addnotification', function(name,message)
    if not guiEnabled then
      SendNUIMessage({
          openSection = "newemail"
      }) 
    end 
    curNotifications[#curNotifications+1] = { ["name"] = name, ["message"] = message }
end)



RegisterNetEvent('YellowPageArray')
AddEventHandler('YellowPageArray', function(pass)
    YellowPageArray = pass
end)

local currentTwats = {}

RegisterNetEvent('Client:UpdateTweet')
AddEventHandler('Client:UpdateTweet', function(tweet)

    local handle = exports["isPed"]:isPed("twitterhandle")
    currentTwats[#currentTwats+1] = tweet 
    
    if not hasPhone() then
      return
    end


    if currentTwats[#currentTwats]["handle"] == handle then
      SendNUIMessage({openSection = "twatter", twats = currentTwats, myhandle = handle})
    end

    if string.find(currentTwats[#currentTwats]["message"],handle) then
      --
      if currentTwats[#currentTwats]["handle"] ~= handle then
        SendNUIMessage({openSection = "newtweet"})
      end


      if phoneNotifications then
        PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
        TriggerEvent("DoLongHudText","You were just mentioned in a tweet on your phone.",15)
      end
    end

    if allowpopups and not guiEnabled then
      SendNUIMessage({openSection = "notify", handle = currentTwats[#currentTwats]["handle"], message =currentTwats[#currentTwats]["message"]})
    end

end)

function createGeneralAreaBlip(alertX, alertY, alertZ)
  local genX = alertX + math.random(-50, 50)
  local genY = alertY + math.random(-50, 50)
  local alertBlip = AddBlipForRadius(genX,genY,alertZ,75.0) 
  SetBlipColour(alertBlip,1)
  SetBlipAlpha(alertBlip,80)
  SetBlipSprite(alertBlip,9)
  Wait(60000)
  RemoveBlip(alertBlip)
end

RegisterNetEvent('phone:triggerHOAAlert')
AddEventHandler('phone:triggerHOAAlert', function(pAlertLocation, pAlertX, pAlertY, pAlertZ)
  local hoaRank = GroupRank("hoa")
  if hoaRank > 0 then
    SendNUIMessage({
      openSection = "hoa-notification",
      alertLocation = pAlertLocation
    })
    createGeneralAreaBlip(pAlertX, pAlertY, pAlertZ)
  end
end)

local lastTime = 0;
RegisterNetEvent('phone:triggerPager')
AddEventHandler('phone:triggerPager', function()
  local job = exports["isPed"]:isPed("myjob")
  if job == "doctor" then
    local currentTime = GetGameTimer()
    if lastTime == 0 or lastTime + (5 * 60 * 1000) < currentTime then
      TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 3.0, 'pager', 0.4)
      SendNUIMessage({
        openSection = "newpager"
      })
      lastTime = currentTime
    end
  end
end)

local customGPSlocations = {
  [1] = { ["x"] = 484.77066040039, ["y"] = -77.643089294434, ["z"] = 77.600166320801, ["info"] = "Garage A"},
  [2] = { ["x"] = -331.96115112305, ["y"] = -781.52337646484, ["z"] = 33.964477539063,  ["info"] = "Garage B"},
  [3] = { ["x"] = -451.37295532227, ["y"] = -794.06591796875, ["z"] = 30.543809890747, ["info"] = "Garage C"},
  [4] = { ["x"] = 399.51190185547, ["y"] = -1346.2742919922, ["z"] = 31.121940612793, ["info"] = "Garage D"},
  [5] = { ["x"] = 598.77319335938, ["y"] = 90.707237243652, ["z"] = 92.829048156738, ["info"] = "Garage E"},
  [6] = { ["x"] = 641.53442382813, ["y"] = 205.42562866211, ["z"] = 97.186958312988, ["info"] = "Garage F"},
  [7] = { ["x"] = 82.359413146973, ["y"] = 6418.9575195313, ["z"] = 31.479639053345, ["info"] = "Garage G"},
  [8] = { ["x"] = -794.578125, ["y"] = -2020.8499755859, ["z"] = 8.9431390762329, ["info"] = "Garage H"},
  [9] = { ["x"] = -669.15631103516, ["y"] = -2001.7552490234, ["z"] = 7.5395741462708, ["info"] = "Garage I"},
  [10] = { ["x"] = -606.86322021484, ["y"] = -2236.7624511719, ["z"] = 6.0779848098755, ["info"] = "Garage J"},
  [11] = { ["x"] = -166.60482788086, ["y"] = -2143.9333496094, ["z"] = 16.839847564697, ["info"] = "Garage K"},
  [12] = { ["x"] = -38.922565460205, ["y"] = -2097.2663574219, ["z"] = 16.704851150513, ["info"] = "Garage L"},
  [13] = { ["x"] = -70.179389953613, ["y"] = -2004.4139404297, ["z"] = 18.016941070557, ["info"] = "Garage M"},
  [14] = { ["x"] = 549.47796630859, ["y"] = -55.197559356689, ["z"] = 71.069190979004, ["info"] = "Garage Impound Lot"},
  [15] = { ["x"] = 364.27685546875, ["y"] = 297.84490966797, ["z"] = 103.49515533447, ["info"] = "Garage O"},
  [16] = { ["x"] = -338.31619262695, ["y"] = 266.79782104492, ["z"] = 85.741966247559, ["info"] = "Garage P"},
  [17] = { ["x"] = 273.66683959961, ["y"] = -343.83737182617, ["z"] = 44.919876098633, ["info"] = "Garage Q"},
  [18] = { ["x"] = 66.215492248535, ["y"] = 13.700443267822, ["z"] = 69.047248840332, ["info"] = "Garage R"},
  [19] = { ["x"] = 3.3330917358398, ["y"] = -1680.7877197266, ["z"] = 29.170293807983, ["info"] = "Garage Imports"},
  [20] = { ["x"] = 286.67013549805, ["y"] = 79.613700866699, ["z"] = 94.362899780273, ["info"] = "Garage S"},
  [21] = { ["x"] = 211.79, ["y"] = -808.38, ["z"] = 30.833, ["info"] = "Garage T"},
  [22] = { ["x"] = 447.65, ["y"] = -1021.23, ["z"] = 28.45, ["info"] = "Garage Police Department"},
  [23] = { ["x"] = -25.59, ["y"] = -720.86, ["z"] = 32.22, ["info"] = "Garage House"},
  [24] =  { ['x'] = -836.93,['y'] = -1273.09,['z'] = 5.01, ['info'] = 'Garage U' },
  [25] = { ['x'] = -1563.23,['y'] = -257.64,['z'] = 48.28, ['info'] = 'Garage V' },
  [26] = { ['x'] = -1327.67,['y'] = -927.44,['z'] = 11.21, ['info'] = 'Garage W' },

}
local loadedGPS = false
RegisterNetEvent('openGPS')
AddEventHandler('openGPS', function(mansions,house,rented)
  -- THIS IS FUCKING PEPEGA TOO.....


  if loadedGPS then
    SendNUIMessage({openSection = "GPS"})
    return
  end
  local mapLocationsObject = {
    custom = { info = customGPSlocations, houseType = 69 },
    mansions = { info = mansions, houseType = 2 },
    houses = { info = house, houseType = 1 },
    rented = { info = rented, houseType = 3 }
  }
  SendNUIMessage({openSection = "GPS", locations = mapLocationsObject })
  loadedGPS = true
end)




RegisterNUICallback('loadUserGPS', function(data)
      TriggerEvent("GPS:SetRoute",data.house_id,data.house_type)
end)


RegisterNUICallback('btnTwatter', function()
  local handle = exports["isPed"]:isPed("twitterhandle")
  SendNUIMessage({openSection = "twatter", twats = currentTwats, myhandle = handle})
end)




RegisterNUICallback('newTwatSubmit', function(data, cb)
    local handle = exports["isPed"]:isPed("twitterhandle")
    TriggerServerEvent('Tweet', handle, data.twat, data.time)   
 
end)

RegisterNUICallback('btnCamera', function()
    SetCustomNuiFocus(false,false)
    SetCustomNuiFocus(true,true)
end)

RegisterNUICallback('accountInformation', function()
  -- FUCK YOU KOIL
  local responseObject = {
    cash = exports["isPed"]:isPed("mycash"),
    bank = exports["isPed"]:isPed("mybank"),
    job = exports["isPed"]:isPed("myjob"),
    secondaryJob = exports["isPed"]:isPed("secondaryjob"),
    licenses = exports["isPed"]:isPed("licensestring"),
    pagerStatus = exports["isPed"]:isPed("pagerstatus")
  }
  SendNUIMessage({openSection = "accountInformation", response = responseObject})
end)

RegisterNUICallback('settings', function()
  local controls = exports["np-base"]:getModule("DataControls"):getBindTable()
  local settings = exports["np-base"]:getModule("SettingsData"):getSettingsTable()
  SendNUIMessage({openSection = "settings", currentControls = controls, currentSettings = settings})
end)

RegisterNUICallback('settingsUpdateToko', function(data, cb)
  if data.tag == "settings" then
    exports["np-base"]:getModule("SettingsData"):setSettingsTableGlobal(data.settings, true)
  elseif data.tag == "controlUpdate" then
    exports["np-base"]:getModule("DataControls"):encodeSetBindTable(data.controls)
  end
end)

RegisterNUICallback('settingsResetToko', function()
  TriggerEvent("np-base:cl:player_reset", "tokovoip")
end)

RegisterNUICallback('settingsResetControls', function()
  TriggerEvent("np-base:cl:player_control", nil)
end)

RegisterNUICallback('notificationsYP', function()
  TriggerEvent("YPUpdatePhone");
end)


RegisterNUICallback('notifications', function()

    lstnotifications = {}

    for i = 1, #curNotifications do

        local message2 = {
          id = tonumber(i),
          name = curNotifications[tonumber(i)].name,
          message = curNotifications[tonumber(i)].message
        }

        lstnotifications[#lstnotifications+1]= message2
    end

    
  SendNUIMessage({openSection = "notifications", list = lstnotifications})

end)

--[[RegisterNetEvent('phone:loadSMSOther')
AddEventHandler('phone:loadSMSOther', function(messages,mynumber)
  openGui()
  lstMsgs = {}
  if (#messages ~= 0) then
    for k,v in pairs(messages) do
      if v ~= nil then
        local msgDisplayName = ""
        if v.receiver == mynumber then
          msgDisplayName = getContactName(v.sender)
        else
          msgDisplayName = getContactName(v.receiver)
        end
        local message = {
          id = tonumber(v.id),
          msgDisplayName = msgDisplayName,
          sender = tonumber(v.sender),
          receiver = tonumber(v.receiver),
          date = tonumber(v.date),
          message = v.message
        }
        lstMsgs[#lstMsgs+1]= message
      end
    end
  end
  print(json.encode(messages))
  SendNUIMessage({openSection = "messagesOther", list = lstMsgs, clientNumber = mynumber})
end)]]




RegisterNetEvent('phone:newSMS')
AddEventHandler('phone:newSMS', function(id, number, message, mypn, date, recip)
  lastnumber = number
  if hasPhone() then

    SendNUIMessage({
        openSection = "newsms"
    })
    
    if phoneNotifications then
      TriggerEvent("DoLongHudText","You just received a new SMS.",16)
      PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
    end
  end
end)

-- SMS Events
RegisterNetEvent('phone:loadSMS')
AddEventHandler('phone:loadSMS', function(messages,mynumber)

  
  lstMsgs = {}
  if (#messages ~= 0) then
    for k,v in pairs(messages) do
      if v ~= nil then
        local msgDisplayName = ""
        if v.receiver ~= mynumber then
          msgDisplayName = getContactName(v.sender)
        else
          msgDisplayName = getContactName(v.receiver)
        end
        local message = {
          id = tonumber(v.id),
          msgDisplayName = msgDisplayName,
          sender = tonumber(v.sender),
          receiver = tonumber(v.receiver),
          date = v.date,
          message = v.message
        }
        lstMsgs[#lstMsgs+1] = message
      end
    end
  end
  print(json.encode(messages))
  SendNUIMessage({openSection = "messages", list = lstMsgs, clientNumber = mynumber})
end)


RegisterNetEvent('phone:sendSMS')
AddEventHandler('phone:sendSMS', function(number, message)
  if(number ~= nil and message ~= nil) then
    TriggerServerEvent('phone:sendSMS', number, message)
    Citizen.Wait(1000)
    TriggerServerEvent('phone:getSMSc')
  else
    phoneMsg("You must fill in a number and message!")
  end
end)

local lastnumber = 0

-- read -- cellphone_text_read_base
-- texting -- cellphone_swipe_screen
-- phone away -- cellphone_text_out

local isInTrunk = false

Citizen.CreateThread(function()
  while true do
    isInTrunk = exports["isPed"]:isPed("intrunk")
    Citizen.Wait(500)
  end
end)


RegisterNetEvent('animation:sms')
AddEventHandler('animation:sms', function(enable)
  TriggerEvent("destroyPropPhone")
  local lPed = PlayerPedId()
  inPhone = enable

  RequestAnimDict("cellphone@")
  while not HasAnimDictLoaded("cellphone@") do
    Citizen.Wait(0)
  end

  if not isInTrunk then
    TaskPlayAnim(lPed, "cellphone@", "cellphone_text_in", 2.0, 3.0, -1, 49, 0, 0, 0, 0)
  end
  Citizen.Wait(300)
  if inPhone then
    TriggerEvent("attachItemPhone","phone01")
    Citizen.Wait(150)
    while inPhone do
      if isDead then
        closeGui()
        inPhone = false
      end
      if not isInTrunk and not IsEntityPlayingAnim(lPed, "cellphone@", "cellphone_text_read_base", 3) and not IsEntityPlayingAnim(lPed, "cellphone@", "cellphone_swipe_screen", 3) then
        TaskPlayAnim(lPed, "cellphone@", "cellphone_text_read_base", 2.0, 3.0, -1, 49, 0, 0, 0, 0)
      end    
      Citizen.Wait(1)
    end
    if not isInTrunk then
      ClearPedTasks(PlayerPedId())
    end
  else
    if not isInTrunk then
      Citizen.Wait(100)
      ClearPedTasks(PlayerPedId())
      TaskPlayAnim(lPed, "cellphone@", "cellphone_text_out", 2.0, 1.0, 5.0, 49, 0, 0, 0, 0)
      Citizen.Wait(400)
      TriggerEvent("destroyPropPhone")
      Citizen.Wait(400)
      ClearPedTasks(PlayerPedId())
    else
      TriggerEvent("destroyPropPhone")
    end
  end
end)

local inTablet = false
RegisterNetEvent('animation:tablet')
AddEventHandler('animation:tablet', function(enable)
  TriggerEvent("destroyPropPhone")
  local lPed = PlayerPedId()
  inPhone = enable
  if inPhone then
    TriggerEvent("attachItemPhone","tablet01")
    while inPhone do
      RequestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@base")
      while not HasAnimDictLoaded("amb@code_human_in_bus_passenger_idles@female@tablet@base") do
        Citizen.Wait(0)
      end
  
      local dead = exports["isPed"]:isPed("dead")
      if dead then
        closeGui()
        inPhone = false
      end

      local intrunk = exports["isPed"]:isPed("intrunk")

      if not intrunk and not IsEntityPlayingAnim(lPed, "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 3) then
        TaskPlayAnim(lPed, "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 3.0, 3.0, -1, 49, 0, 0, 0, 0)
      end
    
      Citizen.Wait(1)
    end

  else

    TriggerEvent("destroyPropPhone")
    local intrunk = exports["isPed"]:isPed("intrunk")
    if not intrunk then
      ClearPedTasks(PlayerPedId())
    end
  end
end)

RegisterNetEvent('phone:reply')
AddEventHandler('phone:reply', function(message)
  if lastnumber ~= 0 then
    TriggerServerEvent('phone:sendSMS', lastnumber, message)
    TriggerEvent("chatMessage", "You", 6, message)
  else
    phoneMsg("No user has recently SMS'd you.")
  end
end)



function phoneMsg(inputText)
  TriggerEvent("chatMessage", "Service ", 5, inputText)
end


RegisterNetEvent("house:returnKeys")
AddEventHandler("house:returnKeys", function(pSharedKeys)
  SendNUIMessage({
    openSection = "manageKeys",
    sharedKeys = pSharedKeys
  })
end)


RegisterNetEvent('phone:deleteSMS')
AddEventHandler('phone:deleteSMS', function(id)
  table.remove( lstMsgs, tablefindKeyVal(lstMsgs, 'id', tonumber(id)))
  phoneMsg("Message Removed!")
end)

function getContactName(number)
  if (#lstContacts ~= 0) then
    for k,v in pairs(lstContacts) do
      if v ~= nil then
        if (v.number ~= nil and tonumber(v.number) == tonumber(number)) then
          return v.name
        end
      end
    end
  end

  return number
end

-- Contact Events
RegisterNetEvent('phone:loadContacts')
AddEventHandler('phone:loadContacts', function(contacts)

  lstContacts = {}

  if (#contacts ~= 0) then
    for k,v in pairs(contacts) do
      if v ~= nil then
        local contact = {
        }
        if activeNumbersClient['active' .. tonumber(v.number)] then
        
          contact = {
            name = v.name,
            number = v.number,
            activated = 1
          }
        else
    
          contact = {
            name = v.name,
            number = v.number,
            activated = 0
          }
        end
        lstContacts[#lstContacts+1]= contact

        SendNUIMessage({
          newContact = true,
          contact = contact,
        })
      end
    end
  else
       SendNUIMessage({
        emptyContacts = true
      })
  end
end)

RegisterNetEvent('phone:addContact')
AddEventHandler('phone:addContact', function(name, number)
  if(name ~= nil and number ~= nil) then
    number = tonumber(number)
    TriggerServerEvent('phone:addContact', name, number)
  else
     phoneMsg("You must fill in a name and number!")
  end
end)

RegisterNetEvent('phone:newContact')
AddEventHandler('phone:newContact', function(name, number)
  local contact = {
      name = name,
      number = number
  }
  lstContacts[#lstContacts+1]= contact

  SendNUIMessage({
    newContact = true,
    contact = contact,
  })
  phoneMsg("Contact Saved!")
  TriggerServerEvent('phone:getContacts')
end)

RegisterNetEvent('phone:deleteContact')
AddEventHandler('phone:deleteContact', function(name, number)

  local contact = {
      name = name,
      number = number
  }

  table.remove( lstContacts, tablefind(lstContacts, contact))
  
  SendNUIMessage({
    deleteContact = true,
    contact = contact,
  })
  
end)



function tablefind(tab,el)
  for index, value in pairs(tab) do
    if value == el then
      return index
    end
  end
end

function tablefindKeyVal(tab,key,val)
  for index, value in pairs(tab) do
    if value ~= nil  and value[key] ~= nil and value[key] == val then
      return index
    end
  end
end


RegisterNetEvent('resetPhone')
AddEventHandler('resetPhone', function()
     SendNUIMessage({
      emptyContacts = true
    })

end)

local weather = ""
RegisterNetEvent("kWeatherSync")
AddEventHandler("kWeatherSync", function(pWeather)
  weather = pWeather
end)

RegisterNUICallback('getWeather', function(data, cb)
  SendNUIMessage({openSection = "weather", weather = weather})
  cb("ok")
end)

function MyPlayerId()
  for i=0,256 do
    if(NetworkIsPlayerActive(i) and GetPlayerPed(i) == PlayerPedId()) then return i end
  end
  return nil
end

function Voip(intPlayer, boolSend)
  --Citizen.InvokeNative(0x97DD4C5944CC2E6A, intPlayer, boolSend)
end