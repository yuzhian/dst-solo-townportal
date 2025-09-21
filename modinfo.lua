name = "单人传送塔"
description = [[
单人传送塔：触摸懒人传送塔，打开地图，选择目标，允许传送到任意传送塔。

传送部分根据模组修改:
[巨兽掉落加强](https://steamcommunity.com/sharedfiles/filedetails/?id=2788995386)
[单人传送塔](https://steamcommunity.com/sharedfiles/filedetails/?id=3389031461)
]]
author = "yuzhian"
version = "0.0.1"
forumthread = ""
api_version = 10
priority = 10
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
server_filter_tags = {}
icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = {
    {
        name = "auto_open_map",
        label = "触摸传送塔时弹出地图",
        hover = "触摸传送塔时自动弹出地图，也可禁用后手动打开地图传送。",
        options = {
            { description = "启用", data = true },
            { description = "禁用", data = false },
        },
        default = true,
    },
    {
        name = "open_map_delay",
        label = "地图弹出延迟",
        hover = "触摸传送塔后延迟弹出地图的时间，单位为秒，禁用自动弹出地图时此项无效。",
        options = {
            { description = "0", data = 0 },
            { description = "0.5", data = 0.5 },
            { description = "1.0", data = 1.0 },
            { description = "2.0", data = 2.0 },
            { description = "3.0", data = 3.0 },
            { description = "5.0", data = 5.0 },
        },
        default = 0.5,
    },
    {
        name = "cost_sanity",
        label = "传送消耗精神值",
        hover = "传送塔传送时消耗精神值。",
        options = {
            { description = "0", data = 0 },
            { description = "15", data = 15 },
            { description = "30", data = 30 },
            { description = "50(原版默认)", data = 50 },
            { description = "100", data = 100 },
        },
        default = 50,
    },
    {
        name = "cost_type",
        label = "传送消耗物品类型",
        hover = "传送塔传送时消耗的物品类型，选择无则不消耗任何物品。",
        options = {
            { description = "无", data = "none" },
            { description = "噩梦燃料", data = "nightmarefuel" },
            { description = "沙之石", data = "townportaltalisman" },
        },
        default = "none",
    },
    {
        name = "cost_count",
        label = "传送消耗物品数量",
        hover = "传送塔传送时消耗的物品数量，物品类型为无时此项无效。",
        options = {
            { description = "0", data = 0 },
            { description = "1", data = 1 },
            { description = "2", data = 2 },
            { description = "3", data = 3 },
            { description = "5", data = 5 },
            { description = "10", data = 10 },
            { description = "20", data = 20 },
            { description = "40", data = 40 },
        },
        default = 1,
    }
}
