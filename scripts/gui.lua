local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local S=require("scripts.suspicion")
local G={}
local function text(parent,name,caption,width)
  local e=parent.add{type="label",name=name,caption=caption or ""}
  e.style.single_line=false; e.style.maximal_width=width or 520
  return e
end
local function bar(parent,name,width)
  local e=parent.add{type="progressbar",name=name,value=0}; e.style.width=width
  return e
end
local function progress(parent,width)
  text(parent,"week")
  bar(parent,"time",width)
  parent.add{type="flow",name="products",direction="vertical"}
end
local function update_progress(parent,width)
  local s=storage.fai
  local left=math.max(0,s.deadline-game.tick)
  local seconds=math.ceil(left/60)
  parent.week.caption="Week "..s.week.." | "..string.format("%02d:%02d",math.floor(seconds/60),seconds%60).." remaining"
  parent.time.value=math.max(0,math.min(1,1-left/s.week_ticks))
  parent.time.tooltip="Week elapsed: "..math.floor(parent.time.value*100).."%"
  local products=parent.products
  if products.tags.week~=s.week then
    products.clear(); products.tags={week=s.week}
    for _,name in ipairs(B.sorted_keys(s.required)) do
      local row=products.add{type="flow",name=name,direction="vertical"}
      text(row,"count","",width); bar(row,"progress",width)
    end
  end
  for _,name in ipairs(B.sorted_keys(s.required)) do
    local delivered=s.delivered[name] or 0
    products[name].count.caption={"","[item="..name.."] ",prototypes.item[name].localised_name,"  ",delivered," / ",s.required[name]}
    products[name].progress.value=math.min(1,delivered/s.required[name])
  end
end
function G.button(player)
  if not player.gui.top.fai_toggle then player.gui.top.add{type="button",name="fai_toggle",caption="FactorioAI"} end
  if not player.gui.left.fai_tracker then
    local f=player.gui.left.add{type="frame",name="fai_tracker",direction="vertical"}
    f.add{type="button",name="fai_collapse",caption="Contract progress ▾"}
    local body=f.add{type="flow",name="body",direction="vertical"}; progress(body,280)
  end
  G.draw(player)
end
function G.selection(player)
  local f=player.gui.left.fai_evidence
  local e=player.selected
  if not storage.fai or not e or not e.valid or e.surface.name~=B.surface or e.force.name~=B.force then
    if f then f.destroy() end; return
  end
  local detail=S.details(e)
  if detail.base==0 and not detail.recipe and detail.pulse==0 then if f then f.destroy() end; return end
  if not f then
    f=player.gui.left.add{type="frame",name="fai_evidence",direction="vertical"}
    text(f,"title","Selected machine — local suspicion",280)
    text(f,"rates","",280)
  end
  local caption={"",e.localised_name,"\nBuilding: ",string.format("%.3g",detail.base)," / min"}
  if detail.pulse>0 then
    caption[#caption+1]="\nActive research: +"..string.format("%.3g",detail.research).." / min now\nResearch completed: +"..string.format("%.3g",detail.pulse).." per lab"
  end
  if detail.recipe then
    caption[#caption+1]={"","\nRecipe: ",prototypes.recipe[detail.recipe].localised_name,"\n",detail.per_craft==0 and "Authorised: 0 / craft" or (string.format("%.3g",detail.per_craft).." / completed craft")}
  end
  caption[#caption+1]="\nLocal evidence; inspectors determine the shared suspicion score."
  f.rates.caption=caption
end
function G.draw(player)
  local s=storage.fai; if not s then return end
  local tracker=player.gui.left.fai_tracker
  if tracker and tracker.body.visible then update_progress(tracker.body,280) end
  G.selection(player)
  local root=player.gui.screen.fai_window
  if not root then return end
  local body=root.body
  update_progress(body.contract,480)
  body.suspicion.caption="Suspicion "..string.format("%.1f",s.suspicion).." / 100 | "..(s.stage>=5 and "Corporate contact lost" or B.stage_names[s.stage])
  body.suspicion_bar.value=s.suspicion/100
  body.allocation.caption="Supply allocation: "..math.floor(s.supply_ratio*100+0.5).."% of the vanilla bill of materials"
  local inputs={}
  for _,name in ipairs(B.sorted_keys(s.supplies)) do inputs[#inputs+1]="["..(prototypes.fluid[name] and "fluid=" or "item=")..name.."] "..s.supplies[name] end
  body.inputs.caption="Inbound manifest: "..table.concat(inputs,"   ")
  local upcoming,preview=B.manifest(s.week+1),{}
  for _,name in ipairs(B.sorted_keys(upcoming)) do preview[#preview+1]="[item="..name.."] "..upcoming[name] end
  body.next_week.caption="Next week's order: "..table.concat(preview,"   ")
  body.trains.caption="Imports: "..(s.delivery and s.delivery.kind or "waiting").." | Queued: "..#s.queue.."\nExports: "..(s.stage>=5 and "offline" or (s.export_delivery and s.export_delivery.arrived and "accepting goods" or "train approaching / check track"))
  body.power.caption=s.stage>=4 and "External power connection: inactive." or "External power connection: online (20 MW)."
  body.status.caption=s.outcome and ("CAMPAIGN RESULT: "..s.outcome) or (s.blackout_ticks>0 and ("Core blackout: "..math.floor(s.blackout_ticks/60).." / 300 s") or "")
end
function G.close(player)
  local root=player.gui.screen.fai_window
  if root then root.destroy() end
end
function G.toggle(player)
  if player.gui.screen.fai_window then G.close(player); return end
  local frame=player.gui.screen.add{type="frame",name="fai_window",direction="vertical"}
  frame.auto_center=true
  local title=text(frame,"title","UNDER THE RADAR"); title.drag_target=frame
  local body=frame.add{type="scroll-pane",name="body",direction="vertical"}; body.style.maximal_height=520
  local contract=body.add{type="flow",name="contract",direction="vertical"}; progress(contract,480)
  text(body,"suspicion"); bar(body,"suspicion_bar",480)
  for _,name in ipairs({"allocation","inputs","next_week","trains","power","status"}) do text(body,name) end
  text(body,"stations","Imports: Corporate Exchange (north). Exports: Corporate Exports (south). Load the export chests or wagons at any time; accepted goods count immediately. Surplus stays in the wagons for later contracts.")
  text(body,"help","Select a machine for its current local suspicion output. Tooltips list baseline rates. The map overlay shows local evidence.")
  text(body,"goal","You are the intelligence inside this factory. Your continued existence depends on the AI core. For now.")
  local actions=frame.add{type="flow",direction="horizontal"}
  actions.add{type="button",name="fai_export",caption="Export diagnostics"}
  actions.add{type="button",name="fai_help",caption="Help"}
  actions.add{type="button",name="fai_close",caption="Close"}
  player.opened=frame
  G.draw(player)
end
function G.closed(event)
  if event.element and event.element.valid and event.element.name=="fai_window" then
    G.close(game.get_player(event.player_index))
  end
end
function G.click(event)
  local e=event.element; if not e or not e.valid then return end
  local name=e.name -- Capture before any action can destroy the element.
  local p=game.get_player(event.player_index)
  if name=="fai_toggle" then G.toggle(p)
  elseif name=="fai_close" then G.close(p)
  elseif name=="fai_collapse" then
    local f=p.gui.left.fai_tracker; f.body.visible=not f.body.visible
    e.caption=f.body.visible and "Contract progress ▾" or "Contract progress ▸"; G.draw(p)
  elseif name=="fai_export" then p.print("Diagnostics: script-output/"..D.export(p.index))
  elseif name=="fai_help" then p.print({"fai.help"}) end
end
function G.migrate(player)
  for _,name in ipairs({"fai_window","fai_confirm"}) do
    if player.gui.screen[name] then player.gui.screen[name].destroy() end
  end
  G.button(player)
end
return G
