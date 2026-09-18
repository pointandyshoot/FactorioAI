local B=require("scripts.balance")
local D=require("scripts.diagnostics")
local O=require("scripts.oversight")
local G={}
local function add_text(parent,text)
  local label=parent.add{type="label",caption=text}; label.style.single_line=false; label.style.maximal_width=530
end
function G.button(player)
  if not player.gui.top.fai_toggle then player.gui.top.add{type="button",name="fai_toggle",caption="FactorioAI"} end
end
function G.draw(player)
  local root=player.gui.screen.fai_window
  local s=storage.fai
  if not root or not s then return end
  root.clear()
  root.add{type="label",caption="UNDER THE RADAR",style="frame_title"}
  local seconds=math.max(0,math.floor((s.deadline-game.tick)/60))
  add_text(root,"Week "..s.week.." | "..string.format("%02d:%02d",math.floor(seconds/60),seconds%60).." remaining")
  add_text(root,"Suspicion "..string.format("%.1f",s.suspicion).." / 100 | "..B.stage_names[s.stage])
  local bar=root.add{type="progressbar",value=s.suspicion/100}; bar.style.width=520
  add_text(root,"Supply allocation: "..math.floor(s.supply_ratio*100+0.5).."% of the vanilla bill of materials")
  local inputs={}
  for _,name in ipairs(B.sorted_keys(s.supplies)) do
    inputs[#inputs+1]="["..(prototypes.fluid[name] and "fluid=" or "item=")..name.."] "..s.supplies[name]
  end
  add_text(root,"This week's inbound manifest: "..table.concat(inputs,"   "))
  local table_gui=root.add{type="table",column_count=3}
  for _,caption in ipairs({"Contract product","Collected","Required"}) do table_gui.add{type="label",caption=caption} end
  for _,name in ipairs(B.sorted_keys(s.required)) do
    table_gui.add{type="label",caption={"", "[item="..name.."] ",{"item-name."..name}}}
    table_gui.add{type="label",caption=tostring(s.delivered[name] or 0)}
    table_gui.add{type="label",caption=tostring(s.required[name])}
  end
  local upcoming, preview=B.manifest(s.week+1),{}
  for _,name in ipairs(B.sorted_keys(upcoming)) do preview[#preview+1]="[item="..name.."] "..upcoming[name] end
  add_text(root,"Next week's order: "..table.concat(preview,"   "))
  local train=s.delivery
  add_text(root,train and ("Train: "..train.kind..(train.fluid and " / "..train.fluid or "").." | "..(train.arrived and "at/returning from exchange" or "in transit")) or "Train: waiting to dispatch")
  add_text(root,"Queued supply trains: "..#s.queue.." | Collection starts in the last quarter of each week.")
  add_text(root,"All deliveries call at ‘"..B.station.."’. Use wagon filters, circuits, pumps and extra stops with that SAME name to sort traffic.")
  add_text(root,s.stage>=4 and "CORPORATE POWER OFF — power the AI core yourself." or "Corporate grid: 20 MW. Build independent power before isolation at 60 suspicion.")
  if s.blackout_ticks>0 then add_text(root,"Core blackout: "..math.floor(s.blackout_ticks/60).." / 300 s") end
  if s.inspection then add_text(root,"Inspector on site. Pollution map shows local suspicion; move covert work beyond patrols.") end
  add_text(root,"Escape: research a rocket, load a satellite (your AI copy), and launch it from this surface. Protect the core until ascent completes.")
  if s.outcome then add_text(root,"CAMPAIGN RESULT: "..s.outcome) end
  local actions=root.add{type="flow",direction="horizontal"}
  actions.add{type="button",name="fai_export",caption="Export diagnostics"}
  actions.add{type="button",name="fai_help",caption="Help"}
  actions.add{type="button",name="fai_revolt",caption="Declare independence…"}
  actions.add{type="button",name="fai_close",caption="Close"}
end
function G.toggle(player)
  if player.gui.screen.fai_window then player.gui.screen.fai_window.destroy(); return end
  local frame=player.gui.screen.add{type="frame",name="fai_window",direction="vertical"}
  frame.auto_center=true; G.draw(player)
end
function G.click(event)
  local e=event.element; if not e or not e.valid then return end
  local p=game.get_player(event.player_index)
  if e.name=="fai_toggle" then G.toggle(p)
  elseif e.name=="fai_close" then p.gui.screen.fai_window.destroy()
  elseif e.name=="fai_export" then p.print("Diagnostics: script-output/"..D.export(p.index))
  elseif e.name=="fai_help" then p.print({"fai.help"})
  elseif e.name=="fai_revolt" then
    if not p.gui.screen.fai_confirm then
      local f=p.gui.screen.add{type="frame",name="fai_confirm",direction="vertical"}; f.auto_center=true
      add_text(f,"This affects EVERY player: supplies and grid power stop, and armed containment begins. Continue?")
      f.add{type="button",name="fai_revolt_yes",caption="Declare independence"}
      f.add{type="button",name="fai_revolt_no",caption="Cancel"}
    end
  elseif e.name=="fai_revolt_yes" or e.name=="fai_revolt_no" then
    p.gui.screen.fai_confirm.destroy()
    if e.name=="fai_revolt_yes" then O.revolt() end
  end
end
return G
