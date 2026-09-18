data:extend({
  {type="int-setting", name="fai-week-minutes", setting_type="runtime-global", default_value=30, minimum_value=5, maximum_value=180, order="a"},
  {type="double-setting", name="fai-suspicion-multiplier", setting_type="runtime-global", default_value=1, minimum_value=0.1, maximum_value=5, order="b"},
  {type="bool-setting", name="fai-debug", setting_type="runtime-global", default_value=false, order="c"},
  {type="bool-setting", name="fai-test-commands", setting_type="runtime-global", default_value=false, order="d"}
})
