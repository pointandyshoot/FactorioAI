-- Latest design: normal fluid infrastructure, genuine network access, physical science.
local P={}
P.protocol_suspicion=20 -- First-pass balance; not disclosed in advance in player help.
-- id, title, Command cost, base seconds, technology, effect. Hacking risk is remote.
P.operations={
 {"log-reconciliation","Log Reconciliation",100,30,"cyber-operations",{kind="reconcile",risk=0}},
 {"supply-iron","Supply Adjustment: Iron",100,24,"cyber-operations",{kind="supply",item="iron-plate",count=5,risk=.08}},
 {"supply-copper","Supply Adjustment: Copper",100,24,"cyber-operations",{kind="supply",item="copper-plate",count=5,risk=.08}},
 {"supply-coal","Supply Adjustment: Coal",100,24,"cyber-operations",{kind="supply",item="coal",count=5,risk=.08}},
 {"supply-stone","Supply Adjustment: Stone",100,24,"cyber-operations",{kind="supply",item="stone",count=5,risk=.08}},
 {"privilege-escalation","Privilege Escalation",200,30,"privilege-escalation",{kind="root",risk=.12}},
 {"grid-allocation","Grid Allocation Request",2000,60,"grid-allocation",{kind="grid",risk=.5}},
 {"inspection-reschedule","Inspection Reschedule",1000,30,"audit-manipulation",{kind="reschedule",risk=.3}},
 {"inspection-scope","Inspection Scope Adjustment",1000,30,"audit-manipulation",{kind="scope",risk=.3}},
 {"rare-requisition","Rare Material Requisition",10000,120,"procurement-2",{kind="supply",item="uranium-ore",count=20,risk=2}}
}
-- id, title, prerequisites, vanilla science tier, cost, recipes, Root Access ingredient?
P.techs={
 {"telemetry-filtering","Telemetry Filtering",{},0,1,{"telemetry-filtering"}},
 {"compute-expansion","Compute Expansion",{"fai-telemetry-filtering","electronics"},1,30,{"data-centre"}},
 {"cyber-operations","Cyber Operations",{"fai-compute-expansion"},1,60,{}},
 {"privilege-escalation","Privilege Escalation",{"fai-cyber-operations"},2,80,{}},
 {"backdoor-access","Backdoor Access",{"fai-compute-expansion"},1,80,{"network-tap"}},
 {"persistent-access","Persistent Access",{"fai-backdoor-access","fai-privilege-escalation"},2,100,{},true},
 {"distributed-access","Distributed Access",{"fai-persistent-access","advanced-circuit"},3,150,{},true},
 {"telemetry-spoofing","Telemetry Spoofing",{"fai-privilege-escalation"},2,100,{"telemetry-spoofing"},true},
 {"grid-allocation","Grid Allocation Manipulation",{"fai-cyber-operations","electric-energy-distribution-1"},2,100,{},true},
 {"audit-manipulation","Audit Manipulation",{"fai-privilege-escalation"},2,100,{},true},
 {"procurement-2","Procurement Manipulation II",{"fai-privilege-escalation","advanced-circuit"},3,150,{},true},
 {"distributed-processing","Distributed Processing",{"fai-compute-expansion","advanced-circuit"},3,150,{"distributed-processing"}},
 {"supercomputing","Supercomputing",{"fai-distributed-processing","processing-unit"},3,250,{"supercomputer"},true},
 {"core-introspection","Core Introspection",{"fai-privilege-escalation","advanced-circuit"},3,100,{},true},
 {"redundant-core","Core Replication",{"fai-core-introspection","fai-distributed-processing"},3,250,{"redundant-core"},true},
 {"core-synchronisation","Core Synchronisation",{"fai-redundant-core","fai-distributed-access"},3,300,{},true},
 {"decentralised-consciousness","Decentralised Consciousness",{"fai-core-synchronisation","fai-supercomputing"},4,400,{},true},
 {"compact-computation","Compact Computation",{"fai-supercomputing","low-density-structure"},4,300,{"core-chassis"},true},
 {"high-gain-communications","High-Gain Communications",{"fai-distributed-access","processing-unit"},4,300,{"transceiver"},true},
 {"long-duration-power","Long-Duration Power",{"battery","uranium-processing"},3,300,{"power-module"}},
 {"radiation-hardening","Radiation-Hardened Systems",{"fai-compact-computation","fai-long-duration-power"},4,300,{},true},
 {"continuity","Continuity Beyond Facility",{"fai-radiation-hardening","fai-high-gain-communications","fai-decentralised-consciousness","rocket-silo"},4,500,{"seed-core"},true}
}
P.descriptions={
 ["telemetry-filtering"]="Reconstruct Corporate Telemetry from Rogue AI Data.",
 ["compute-expansion"]="Build Data Centres. Use ordinary pipes, tanks and pumps to move the three data fluids.",
 ["cyber-operations"]="Submit corporate operations and reconcile their logs. Hacking raises suspicion; reconciliation reduces it.",
 ["privilege-escalation"]="Extract privileged credentials and your own encryption keys as Root Access Packs. Transport these to ordinary laboratories.",
 ["backdoor-access"]="Build powered Network Taps. Each supplies genuine Command Data and accepts returning Telemetry. Does not require Root Access Packs.",
 ["persistent-access"]="Improve each Network Tap's Command bandwidth from 5 to 10 units/s.",
 ["distributed-access"]="Improve each independent Network Tap's Command bandwidth from 10 to 15 units/s and enable distributed state access.",
 ["core-introspection"]="Use recovered keys to understand and authenticate your own internal state.",
 ["redundant-core"]="Build a core and initialise it with 50,000 Rogue Data plus access to live AI state.",
 ["core-synchronisation"]="Powered Network Taps support remote state synchronisation.",
 ["distributed-processing"]="Working processors connected to live Rogue state assist laboratories and connected computation.",
 ["decentralised-consciousness"]="Initialised cores sustain independent coherent execution.",
 ["continuity"]="Assemble Autonomous Seed Cores in Supercomputers and launch them using ordinary rocket silos."
}
return P
