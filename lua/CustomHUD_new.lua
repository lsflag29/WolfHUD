        HUDManager.CUSTOM_TEAMMATE_PANEL = true --External flag
 
        HUDTeamPanelBase = HUDTeamPanelBase or class()
        HUDPlayerPanel = HUDPlayerPanel or class(HUDTeamPanelBase)
        HUDTeammatePanel = HUDTeammatePanel or class(HUDTeamPanelBase)
       
        HUDTeamPanelBase.DEBUG_SHOW_PANEL_AREA = true
       

        HUDPlayerPanel.SCALE = WolfHUD.settings.PLAYER_PANEL_SCALE or 0.85

        HUDPlayerPanel.SHOW_WEAPONS_ICONS = true
        HUDPlayerPanel.SHOW_SELECTED_WEAPON_ICONS_ONLY = false
        HUDPlayerPanel.SHOW_AMMO = true
        HUDPlayerPanel.SHOW_FIRE_MODE = true
        HUDPlayerPanel.SHOW_EQUIPMENT = true
        HUDPlayerPanel.SHOW_SPECIAL_EQUIPMENT = true
        HUDPlayerPanel.SHOW_CARRY_INFO = true
       
        HUDTeammatePanel.SCALE = WolfHUD.settings.TEAMMATE_PANEL_SCALE or 0.75

        HUDTeammatePanel.SHOW_WEAPONS_ICONS = true
        HUDTeammatePanel.SHOW_SELECTED_WEAPON_ICONS_ONLY = false
        HUDTeammatePanel.SHOW_AMMO = true
        HUDTeammatePanel.SHOW_EQUIPMENT = true
        HUDTeammatePanel.SHOW_SPECIAL_EQUIPMENT = true
        HUDTeammatePanel.SHOW_CARRY_INFO = true
        HUDTeammatePanel.SHOW_NAME = true
        HUDTeammatePanel.SHOW_INTERACTIONS = 1  --Min interaction duration to show, or false to show nothing
		HUDTeammatePanel._NAME_ANIMATE_SPEED = 90

 
        function HUDTeamPanelBase:init(width, height, scale, id, parent)
                self._id = id
                self._parent = parent
               
                self._show_selected_weapon_icon_only = self.SHOW_SELECTED_WEAPON_ICONS_ONLY
                self._show_equipment = self.SHOW_EQUIPMENT
                self._show_special_equipment = self.SHOW_SPECIAL_EQUIPMENT
                self._show_carry_info = self.SHOW_CARRY_INFO
               
                self._timer = 0
                self._special_equipment = {}
                self._selected_weapon = 1
               
                self._panel = self._parent:panel({
                        name = "teammates_panel_" .. tostring(self._id),
                        w = width * scale,
                        h = height * scale,
                        visible = false,
                })
               
                self:_create_health_panel(self._panel:h() * 0.75)
                self:_create_callsign_panel(self._health_panel:h())
                self:_create_weapons_panel(self._health_panel:h())
                self:_create_equipment_panel(self._health_panel:h())
                self:_create_special_equipment_panel(self._health_panel:h())
                self:_create_carry_panel()
               
                self:set_show_weapon_icons(self.SHOW_WEAPONS_ICONS)
                self:set_show_ammo(self.SHOW_AMMO)
               
                if HUDTeamPanelBase.DEBUG_SHOW_PANEL_AREA then
                        local test_bg = self._panel:rect({
                                name = "test_bg",
                                blend_mode = "normal",
                                color = Color((self._id / (math.random() * 10 + 1)) % 1, (self._id / (math.random() * 10 + 1)) % 1, (self._id / (math.random() * 10 + 1)) % 1),
                                w = self._panel:w(),
                                h = self._panel:h(),
                                layer = -100,
                                alpha = 0.35,
                        })
                end
       
        end
       
        function HUDTeamPanelBase:set_show_health(status)
                self._health_panel:set_w(status and self._health_default_w or 0)
                self:_arrange_panel()
        end
       
        function HUDTeamPanelBase:set_show_weapon_icons(status)
                self._show_weapon_icons = status
       
                for i = 2, 1, -1 do
                        local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
                        local w = status and (not self._show_selected_weapon_icon_only or i == self._selected_weapon) and sub_panel:h() * 2 or 0
                        sub_panel:child("icon_panel"):set_w(w)
                end
               
                self:_arrange_weapons_panel()
                self:_arrange_panel()
        end
       
        function HUDTeamPanelBase:set_show_ammo(status)
                for i = 2, 1, -1 do
                        self._weapons_panel:child("weapons_panel_" .. i):child("ammo_panel"):set_w(status and self._ammo_panel_default_w or 0)
                end
               
                self:_arrange_weapons_panel()
                self:_arrange_panel()
        end
       
        function HUDTeamPanelBase:set_show_equipment(status)
                self._show_equipment = status
                self:_check_equipment_panel_visibility()
        end
       
        function HUDTeamPanelBase:set_show_special_equipment(status)
                self._show_special_equipment = status
                self:_layout_special_equipments()
        end
       
        function HUDTeamPanelBase:set_show_carry_info(status)
                self._show_carry_info = status
                self:set_carry_info(self._current_carry)
        end
       
        function HUDTeamPanelBase:_arrange_panel()
                self._callsign_panel:set_center(self._health_panel:center())
        end
       
        function HUDTeamPanelBase:panel()
                return self._panel
        end
 
        function HUDTeamPanelBase:peer_id()
                return self._peer_id
        end
       
        function HUDTeamPanelBase:_create_health_panel(size)
                self._health_default_w = size
                self._health_panel = self._panel:panel({
                        name = "radial_health_panel",
                        w = size,
                        h = size,
                })
 
                local health_panel_bg = self._health_panel:bitmap({
                        name = "radial_bg",
                        texture = "guis/textures/pd2/hud_radialbg",
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        layer = 0,
                })
               
                local radial_health = self._health_panel:bitmap({
                        name = "radial_health",
                        texture = "guis/textures/pd2/hud_health",
                        texture_rect = { 64, 0, -64, 64 },
                        render_template = "VertexColorTexturedRadial",
                        blend_mode = "add",
                        color = Color(1, 1, 0, 0),
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        layer = 2,
                })
               
                local radial_shield = self._health_panel:bitmap({
                        name = "radial_shield",
                        texture = "guis/textures/pd2/hud_shield",
                        texture_rect = { 64, 0, -64, 64 },
                        render_template = "VertexColorTexturedRadial",
                        blend_mode = "add",
                        color = Color(1, 1, 0, 0),
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        layer = 1
                })
               
                local damage_indicator = self._health_panel:bitmap({
                        name = "damage_indicator",
                        texture = "guis/textures/pd2/hud_radial_rim",
                        blend_mode = "add",
                        color = Color(1, 1, 1, 1),
                        alpha = 0,
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        layer = 1
                })
                local radial_custom = self._health_panel:bitmap({
                        name = "radial_custom",
                        texture = "guis/textures/pd2/hud_swansong",
                        texture_rect = { 0, 0, 64, 64 },
                        render_template = "VertexColorTexturedRadial",
                        blend_mode = "add",
                        color = Color(1, 0, 0, 0),
                        visible = false,
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        layer = 2
                })
               
                self._condition_icon = self._health_panel:bitmap({
                        name = "condition_icon",
                        layer = 4,
                        visible = false,
                        color = Color.white,
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                })
                self._condition_timer = self._health_panel:text({
                        name = "condition_timer",
                        visible = false,
                        layer = 5,
                        color = Color.white,
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        align = "center",
                        vertical = "center",
                        font_size = self._health_panel:h() * 0.5,
                        font = tweak_data.hud_players.timer_font
                })
        end
       
        function HUDTeamPanelBase:set_health(data)
                local radial_health = self._health_panel:child("radial_health")
                local red = data.current / data.total
                if red < radial_health:color().red then
                        self:_damage_taken()
                end
                radial_health:set_color(Color(1, red, 1, 1))
        end
 
        function HUDTeamPanelBase:set_armor(data)
                local radial_shield = self._health_panel:child("radial_shield")
                local red = data.current / data.total
                if red < radial_shield:color().red then
                        self:_damage_taken()
                end
                radial_shield:set_color(Color(1, red, 1, 1))
        end
 
        function HUDTeamPanelBase:_damage_taken()
                local damage_indicator = self._health_panel:child("damage_indicator")
                damage_indicator:stop()
                damage_indicator:animate(callback(self, self, "_animate_damage_taken"))
        end
       
        function HUDTeamPanelBase:set_condition(icon_data, text)
                if icon_data == "mugshot_normal" then
                        self._condition_icon:set_visible(false)
                else
                        self._condition_icon:set_visible(true)
                        local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
                        self._condition_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
                end
        end
 
        function HUDTeamPanelBase:set_custom_radial(data)
                local radial_custom = self._health_panel:child("radial_custom")
                local red = data.current / data.total
                radial_custom:set_color(Color(1, red, 1, 1))
                radial_custom:set_visible(red > 0)
        end
 
        function HUDTeamPanelBase:start_timer(time)
                self._timer_paused = 0
                self._timer = time
                self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
                self._condition_timer:set_color(Color.white)
                self._condition_timer:stop()
                self._condition_timer:set_visible(true)
                self._condition_timer:animate(callback(self, self, "_animate_timer"))
        end
 
        function HUDTeamPanelBase:stop_timer()
                if alive(self._panel) then
                        self._condition_timer:set_visible(false)
                        self._condition_timer:stop()
                end
        end
 
        function HUDTeamPanelBase:set_pause_timer(pause)
                if not alive(self._panel) then
                        return
                end
                --self._condition_timer:set_visible(false)
                self._condition_timer:stop()
        end
 
        function HUDTeamPanelBase:is_timer_running()
                return self._condition_timer:visible()
        end
       
        function HUDTeamPanelBase:_create_callsign_panel(size)
                self._callsign_panel = self._panel:panel({
                        name = "callsign_panel",
                        w = size,
                        h = size,
                })
               
                local callsign = self._callsign_panel:bitmap({
                        name = "callsign",
                        texture = "guis/textures/pd2/hud_tabs",
                        texture_rect = { 84, 34, 19, 19 },
                        layer = 1,
                        color = Color.white,
                        blend_mode = "normal",
                        w = self._callsign_panel:w() * 0.35,
                        h = self._callsign_panel:h() * 0.35,
                })
                callsign:set_center(self._callsign_panel:w() / 2, self._callsign_panel:h() / 2)
        end
       
        function HUDTeamPanelBase:_create_weapons_panel(height)
                self._weapons_panel = self._panel:panel({
                        name = "weapons_panel",
                        h = height,
                })
               
                self._weapons_panel:rect({
                        name = "bg",
                        blend_mode = "normal",
                        color = Color.black,
                        alpha = 0.25,
                        h = self._weapons_panel:h(),
                        layer = -1,
                })
               
                for i = 2, 1, -1 do
                        local sub_panel = self._weapons_panel:panel({
                                name = "weapons_panel_" .. i,
                                h = self._weapons_panel:h(),
                        })
                       
                        local icon_panel = sub_panel:panel({
                                name = "icon_panel",
                                w = sub_panel:h() * 2,
                                h = sub_panel:h(),
                        })
                       
                        local icon = icon_panel:bitmap({
                                name = "icon",
                                blend_mode = "normal",
                                w = icon_panel:h() * 2,
                                h = icon_panel:h(),
                                layer = 1,
                        })
                       
                        local silencer_icon = icon_panel:bitmap({
                                name = "silencer_icon",
                                texture = "guis/textures/pd2/blackmarket/inv_mod_silencer",
                                blend_mode = "normal",
                                visible = false,
                                w = icon:h() * 0.25,
                                h = icon:h() * 0.25,
                                layer = icon:layer() + 1,
                        })
                        silencer_icon:set_bottom(icon:bottom())
                        silencer_icon:set_right(icon:right())
                       
                        local ammo_panel = sub_panel:panel({
                                name = "ammo_panel",
                                h = sub_panel:h(),
                        })
                       
                        local ammo_clip = ammo_panel:text({
                                name = "ammo_clip",
                                text = "000",
                                color = Color.white,
                                blend_mode = "normal",
                                layer = 1,
                                h = ammo_panel:h() * 0.55,
                                vertical = "center",
                                align = "right",
                                font_size = ammo_panel:h() * 0.55,
                                font = tweak_data.hud_players.ammo_font
                        })
                        ammo_clip:set_top(0)
                       
                        local ammo_total = ammo_panel:text({
                                name = "ammo_total",
                                text = "000",
                                color = Color.white,
                                blend_mode = "normal",
                                layer = 1,
                                h = ammo_panel:h() * 0.45,
                                vertical = "center",
                                align = "right",
                                font_size = ammo_panel:h() * 0.45,
                                font = tweak_data.hud_players.ammo_font
                        })
                        ammo_total:set_bottom(ammo_panel:h())
                       
                        local _, _, w, _ = ammo_clip:text_rect()
                        self._ammo_panel_default_w = w
                        ammo_panel:set_w(w)
                        ammo_clip:set_w(w)
                        ammo_total:set_w(w)
                end
        end
       
        function HUDTeamPanelBase:_arrange_weapons_panel()
                local BIG_MARGIN = 3
                local SMALL_MARGIN = 1
                local total_w = 0
               
                for i = 2, 1, -1 do
                        local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
                        local sub_total_w = 0
                       
                        for _, pid in ipairs({ "icon_panel", "ammo_panel", "firemode_panel" }) do
                                local panel = sub_panel:child(pid)
                                if panel then
                                        panel:set_x(sub_total_w)
                                        if panel:w() > 0 then
                                                sub_total_w = sub_total_w + panel:w() + SMALL_MARGIN
                                        end
                                end
                        end
                       
                        sub_total_w = sub_total_w - (sub_total_w > 0 and SMALL_MARGIN or 0)
                       
                        sub_panel:set_w(sub_total_w)
                        sub_panel:set_x(total_w)
                        total_w = total_w + sub_total_w + (sub_total_w > 0 and BIG_MARGIN or 0)
                end
               
                total_w = total_w - (total_w > 0 and BIG_MARGIN or 0)
               
                self._weapons_panel:set_w(total_w)
                local bg = self._weapons_panel:child("bg")
                bg:set_w(self._weapons_panel:w())
        end
       
        function HUDTeamPanelBase:set_weapon_id(slot, id, silencer)
                local bundle_folder = tweak_data.weapon[id] and tweak_data.weapon[id].texture_bundle_folder
                local guis_catalog = "guis/"
                if bundle_folder then
                        guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
                end
                local texture_name = tweak_data.weapon[id] and tweak_data.weapon[id].texture_name or tostring(id)
                local bitmap_texture = guis_catalog .. "textures/pd2/blackmarket/icons/weapons/" .. texture_name
 
                local panel = self._weapons_panel:child("weapons_panel_" .. slot):child("icon_panel")
                local icon = panel:child("icon")
                local silencer_icon = panel:child("silencer_icon")
                panel:set_visible(true)
                icon:set_image(bitmap_texture)
                silencer_icon:set_visible(silencer)
        end
       
        function HUDTeamPanelBase:set_weapon_selected(id)
                self._selected_weapon = id
               
                for i = 2, 1, -1 do
                        self._weapons_panel:child("weapons_panel_" .. i):set_alpha(i == id and 1 or 0.5)
                end
               
                if self._show_selected_weapon_icon_only then
                        self:set_show_weapon_icons(self._show_weapon_icons)
                end
        end
       
        function HUDTeamPanelBase:set_ammo_amount_by_type(id, max_clip, current_clip, current_left, max)
                local panel = self._weapons_panel:child("weapons_panel_" .. id):child("ammo_panel")
                local low_ammo = current_left <= math.round(max_clip / 2)
                local low_ammo_clip = current_clip <= math.round(max_clip / 4)
                local out_of_ammo_clip = current_clip <= 0
                local out_of_ammo = current_left <= 0
                local color_total = out_of_ammo and Color(1, 0.9, 0.3, 0.3)
                color_total = color_total or low_ammo and Color(1, 0.9, 0.9, 0.3)
                color_total = color_total or Color.white
                local color_clip = out_of_ammo_clip and Color(1, 0.9, 0.3, 0.3)
                color_clip = color_clip or low_ammo_clip and Color(1, 0.9, 0.9, 0.3)
                color_clip = color_clip or Color.white
               
                local ammo_clip = panel:child("ammo_clip")
                local zero = current_clip < 10 and "00" or current_clip < 100 and "0" or ""
                ammo_clip:set_text(zero .. tostring(current_clip))
                ammo_clip:set_color(color_clip)
                ammo_clip:set_range_color(0, string.len(zero), color_clip:with_alpha(0.5))
               
                local ammo_total = panel:child("ammo_total")
                local zero = current_left < 10 and "00" or current_left < 100 and "0" or ""
                ammo_total:set_text(zero .. tostring(current_left))
                ammo_total:set_color(color_total)
                ammo_total:set_range_color(0, string.len(zero), color_total:with_alpha(0.5))
        end    
       
        function HUDTeamPanelBase:_create_equipment_panel(height)
                self._equipment_panel = self._panel:panel({
                        name = "equipment_panel",
                        h = height,
                        w = 0,
                })
               
                for i, name in ipairs({ "deployable_equipment_panel", "cable_ties_panel", "throwables_panel" }) do
                        local panel = self._equipment_panel:panel({
                                name = name,
                                h = self._equipment_panel:h() / 3,
                                w = self._equipment_panel:h() * 0.6,
                                visible = false,
                        })
                       
                        local icon = panel:bitmap({
                                name = "icon",
                                layer = 1,
                                color = Color.white,
                                w = panel:h(),
                                h = panel:h(),
                                layer = 2,
                        })
                       
                        local amount = panel:text({
                                name = "amount",
                                text = "00",
                                font = "fonts/font_medium_mf",
                                font_size = panel:h(),
                                color = Color.white,
                                align = "right",
                                vertical = "center",
                                layer = 2,
                                w = panel:w(),
                                h = panel:h()
                        })
                       
                        local bg = panel:rect({
                                name = "bg",
                                blend_mode = "normal",
                                color = Color.black,
                                alpha = 0.5,
                                h = panel:h(),
                                w = panel:w(),
                                layer = -1,
                        })
                       
                        panel:set_top((i-1) * panel:h())
                end
        end
 
        function HUDTeamPanelBase:_set_amount_string(text, amount)
                local zero = amount < 10 and "0" or ""
                text:set_text(zero .. amount)
                text:set_range_color(0, string.len(zero), Color.white:with_alpha(0.5))
        end
 
        function HUDTeamPanelBase:_check_equipment_panel_visibility()
                local was_visible = self._equipment_panel:w() > 0
                local visible = false
                for _, child in ipairs(self._equipment_panel:children()) do
                        visible = visible or child:visible()
                end
               
                visible = self._show_equipment and visible or false
               
                if was_visible ~= visible then
                        self._equipment_panel:set_w(visible and self._equipment_panel:h() * 0.6 or 0)
                        self:_arrange_panel()
                end
        end
       
        function HUDTeamPanelBase:set_deployable_equipment(data)
                local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
                local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
                local deployable_icon = deployable_equipment_panel:child("icon")
                deployable_icon:set_image(icon, unpack(texture_rect))
                self:set_deployable_equipment_amount(1, data)
        end
 
        function HUDTeamPanelBase:set_deployable_equipment_amount(index, data)
                local deployable_equipment_panel = self._equipment_panel:child("deployable_equipment_panel")
                local deployable_amount = deployable_equipment_panel:child("amount")
                self:_set_amount_string(deployable_amount, data.amount)
                deployable_equipment_panel:set_visible(data.amount ~= 0)
                self:_check_equipment_panel_visibility()
        end
 
        function HUDTeamPanelBase:set_cable_tie(data)
                local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
                local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
                local tie_icon = cable_ties_panel:child("icon")
                tie_icon:set_image(icon, unpack(texture_rect))
                self:set_cable_ties_amount(data.amount)
        end
 
        function HUDTeamPanelBase:set_cable_ties_amount(amount)
                local cable_ties_panel = self._equipment_panel:child("cable_ties_panel")
                self:_set_amount_string(cable_ties_panel:child("amount"), amount)
                cable_ties_panel:set_visible(amount ~= 0)
                self:_check_equipment_panel_visibility()
        end
 
        function HUDTeamPanelBase:set_grenades(data)
                local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
                local throwables_panel = self._equipment_panel:child("throwables_panel")
                local grenade_icon = throwables_panel:child("icon")
                grenade_icon:set_image(icon, unpack(texture_rect))
                self:set_grenades_amount(data)
        end
 
        function HUDTeamPanelBase:set_grenades_amount(data)
                local throwables_panel = self._equipment_panel:child("throwables_panel")
                local amount = throwables_panel:child("amount")
                self:_set_amount_string(amount, data.amount)
                throwables_panel:set_visible(data.amount ~= 0)
                self:_check_equipment_panel_visibility()
        end
       
        function HUDTeamPanelBase:_create_special_equipment_panel(height)
                self._special_equipment_panel = self._panel:panel({
                        name = "special_equipment_panel",
                        h = height,
                        w = 0,
                })
        end
 
        function HUDTeamPanelBase:add_special_equipment(data)
                local size = self._special_equipment_panel:h() / 3
               
                local equipment_panel = self._special_equipment_panel:panel({
                        name = data.id,
                        h = size,
                        w = size,
                })
                table.insert(self._special_equipment, equipment_panel)
               
                local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
                local bitmap = equipment_panel:bitmap({
                        name = "bitmap",
                        texture = icon,
                        color = Color.white,
                        layer = 1,
                        texture_rect = texture_rect,
                        w = equipment_panel:w(),
                        h = equipment_panel:h()
                })
               
                local amount, amount_bg
                if data.amount then
                        amount = equipment_panel:child("amount") or equipment_panel:text({
                                name = "amount",
                                text = tostring(data.amount),
                                font = "fonts/font_small_noshadow_mf",
                                font_size = 12 * equipment_panel:h() / 32,
                                color = Color.black,
                                align = "center",
                                vertical = "center",
                                layer = 4,
                                w = equipment_panel:w(),
                                h = equipment_panel:h()
                        })
                        amount:set_visible(1 < data.amount)
                        amount_bg = equipment_panel:child("amount_bg") or equipment_panel:bitmap({
                                name = "amount_bg",
                                texture = "guis/textures/pd2/equip_count",
                                color = Color.white,
                                layer = 3,
                        })
                        amount_bg:set_size(amount_bg:w() * equipment_panel:w() / 32, amount_bg:h() * equipment_panel:h() / 32)
                        amount_bg:set_center(bitmap:center())
                        amount_bg:move(amount:w() * 0.2, amount:h() * 0.2)
                        amount_bg:set_visible(1 < data.amount)
                        amount:set_center(amount_bg:center())
                end
               
                local flash_icon = equipment_panel:bitmap({
                        name = "bitmap",
                        texture = icon,
                        color = tweak_data.hud.prime_color,
                        layer = 2,
                        texture_rect = texture_rect,
                        w = equipment_panel:w() + 2,
                        h = equipment_panel:w() + 2
                })
               
                local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
                flash_icon:set_center(bitmap:center())
                flash_icon:animate(hud.flash_icon, nil, equipment_panel)
                self:_layout_special_equipments()
        end
 
        function HUDTeamPanelBase:remove_special_equipment(equipment)
                for i, panel in ipairs(self._special_equipment) do
                        if panel:name() == equipment then
                                local data = table.remove(self._special_equipment, i)
                                self._special_equipment_panel:remove(panel)
                                self:_layout_special_equipments()
                                return
                        end
                end
        end
 
        function HUDTeamPanelBase:set_special_equipment_amount(equipment_id, amount)
                for i, panel in ipairs(self._special_equipment) do
                        if panel:name() == equipment_id then
                                panel:child("amount"):set_text(tostring(amount))
                                panel:child("amount"):set_visible(amount > 1)
                                panel:child("amount_bg"):set_visible(amount > 1)
                                return
                        end
                end
        end
 
        function HUDTeamPanelBase:clear_special_equipment()
                self:remove_panel()
                self:add_panel()
        end
 
        function HUDTeamPanelBase:_layout_special_equipments()
                local panel_w = 0
       
                if #self._special_equipment > 0 then
                        local h = self._special_equipment[1]:h()
                        local w = self._special_equipment[1]:w()
                        local items_per_column = math.floor(self._special_equipment_panel:h() / h)
                       
                        for i, panel in ipairs(self._special_equipment) do
                                local column = math.floor((i-1) / items_per_column)
                                panel:set_left(0 + column * w)
                                panel:set_top(0 + (i - 1 - column * items_per_column) * h)
                        end
                       
                        panel_w = math.ceil(#self._special_equipment / items_per_column) * w
                end
               
                self._special_equipment_panel:set_w(self._show_special_equipment and panel_w or 0)
                self:_arrange_panel()
        end
 
        function HUDTeamPanelBase:_create_carry_panel(height)
                self._carry_panel = self._panel:panel({
                        name = "carry_panel",
                        visible = false,
                        h = height,
                        w = 0,
                })
               
                local icon = self._carry_panel:bitmap({
                        name = "icon",
                        visible = false,        --Shows otherwise for some reason...
                        texture = "guis/textures/pd2/hud_tabs",
                        texture_rect = { 32, 33, 32, 31 },
                        w = self._carry_panel:h(),
                        h = self._carry_panel:h(),
                        layer = 1,
                        color = Color.white,
                })
               
                local text = self._carry_panel:text({
                        name = "text",
                        layer = 1,
                        color = Color.white,
                        --w = self._carry_panel:w(),
                        h = self._carry_panel:h(),
                        vertical = "center",
                        align = "center",
                        font_size = self._carry_panel:h(),
                        font = tweak_data.hud.medium_font_noshadow,
                })
               
                self:remove_carry_info()
        end
       
        function HUDTeamPanelBase:set_carry_info(carry_id, value)
                self._current_carry = carry_id
               
                local name_id = carry_id and tweak_data.carry[carry_id] and tweak_data.carry[carry_id].name_id
                local carry_text = utf8.to_upper(name_id and managers.localization:text(name_id) or "UNKNOWN")
                local text = self._carry_panel:child("text")
                local icon = self._carry_panel:child("icon")
               
                text:set_text(carry_text)
                local _, _, w, _ = text:text_rect()
                text:set_w(w)
                icon:set_visible(true)
               
                self._carry_panel:set_visible(true)
                self._carry_panel:animate(callback(self, self, "_animate_carry_pickup"))
        end
 
        function HUDTeamPanelBase:remove_carry_info()
                self._current_carry = nil
                self._carry_panel:stop()
                self._carry_panel:set_w(0)
                self._carry_panel:set_visible(false)
                self._carry_panel:child("icon"):set_visible(false)
                self._carry_panel:child("text"):set_text("")
        end
 
       
        function HUDTeamPanelBase:add_panel()
                self._panel:show()
        end
       
        function HUDTeamPanelBase:remove_panel()
                --TODO: Cleanup
                self._panel:hide()
               
                while self._special_equipment[1] do
                        self._special_equipment_panel:remove(table.remove(self._special_equipment, 1))
                end
               
                self:set_condition("mugshot_normal")
                self:set_cheater(false)
                self:stop_timer()
                self:set_peer_id(nil)
                self:set_ai(nil)
                self:remove_carry_info()
        end
       
        function HUDTeamPanelBase:set_callsign(id)
                self._callsign_panel:child("callsign"):set_color(tweak_data.chat_colors[id]:with_alpha(1))
        end
       
        function HUDTeamPanelBase:set_voice_com(status)
                self._voice_com = status
               
                if status and not self._animating_voice_com then
                        self._callsign_panel:child("callsign"):animate(callback(self, self, "_animate_voice_com"))
                end
        end
       
        function HUDTeamPanelBase:set_peer_id(peer_id)
                self._peer_id = peer_id
 
                local peer = peer_id and managers.network:session():peer(peer_id)
                if peer then
                        local outfit = peer:blackmarket_outfit()
                       
                        for selection, data in ipairs({ outfit.secondary, outfit.primary }) do
                                local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(data.factory_id)
                                local silencer = managers.weapon_factory:has_perk("silencer", data.factory_id, data.blueprint)
                                self:set_weapon_id(selection, weapon_id, silencer)
                        end
                end
        end
       
        function HUDTeamPanelBase:set_ai(ai)
                self._ai = ai
               
                local visible = not ai and true or false
                self._weapons_panel:set_visible(visible)
                self._equipment_panel:set_visible(visible)
                self._special_equipment_panel:set_visible(visible)
                self._callsign_panel:set_visible(visible)
        end
       
        function HUDTeamPanelBase:_animate_damage_taken(damage_indicator)
                damage_indicator:set_alpha(1)
                local st = 3
                local t = st
                local st_red_t = 0.5
                local red_t = st_red_t
                while t > 0 do
                        local dt = coroutine.yield()
                        t = t - dt
                        red_t = math.clamp(red_t - dt, 0, 1)
                        damage_indicator:set_color(Color(1, red_t / st_red_t, red_t / st_red_t))
                        damage_indicator:set_alpha(t / st)
                end
                damage_indicator:set_alpha(0)
        end
       
        function HUDTeamPanelBase:_animate_voice_com(callsign)
                self._animating_voice_com = true
               
                local w, h = callsign:size()
                local x, y = callsign:center()
                callsign:set_image("guis/textures/pd2/jukebox_playing", unpack({ 0, 0, 16, 16 }))
               
                while self._voice_com do
                        local T = 2
                        local t = 0
                       
                        while t < T do
                                local r = (math.sin(t * 360)) * 0.15
                                callsign:set_size(w + w * r, h + h * r)
                                callsign:set_center(x, y)
                                t = t + coroutine.yield()
                        end
                end
               
                callsign:set_image("guis/textures/pd2/hud_tabs", unpack({ 84, 34, 19, 19 }))
                callsign:set_size(w, h)
                callsign:set_center(x, y)
               
                self._animating_voice_com = false
        end
       
        function HUDTeamPanelBase:_animate_timer()
                local rounded_timer = math.round(self._timer)
                while self._timer >= 0 do
                        local dt = coroutine.yield()
                        if self._timer_paused == 0 then
                                self._timer = self._timer - dt
                                local text = self._timer < 0 and "00" or (math.round(self._timer) < 10 and "0" or "") .. math.round(self._timer)
                                self._condition_timer:set_text(text)
                                if rounded_timer > math.round(self._timer) then
                                        rounded_timer = math.round(self._timer)
                                        if rounded_timer < 11 then
                                                self._condition_timer:animate(callback(self, self, "_animate_timer_flash"))
                                        end
                                end
                        end
                end
        end
 
        function HUDTeamPanelBase:_animate_timer_flash()
                local t = 0
                while t < 0.5 do
                        t = t + coroutine.yield()
                        local n = 1 - math.sin(t * 180)
                        local r = math.lerp(1 or self._point_of_no_return_color.r, 1, n)
                        local g = math.lerp(0 or self._point_of_no_return_color.g, 0.8, n)
                        local b = math.lerp(0 or self._point_of_no_return_color.b, 0.2, n)
                        self._condition_timer:set_color(Color(r, g, b))
                        self._condition_timer:set_font_size(math.lerp(self._health_panel:h() * 0.5, self._health_panel:h() * 0.8, n))
                end
                self._condition_timer:set_font_size(self._health_panel:h() * 0.5)
        end
 
        function HUDTeamPanelBase:_animate_carry_pickup(carry_panel)
                local DURATION = 2
                local text = self._carry_panel:child("text")
                local icon = self._carry_panel:child("icon")
               
                local t = DURATION
                while t > 0 do
                        local dt = coroutine.yield()
                        t = math.max(t-dt, 0)
                       
                        local r = math.sin(720 * t) * 0.5 + 0.5
                        text:set_color(Color(1, 1, 1, r))
                        icon:set_color(Color(1, 1, 1, r))
                end
               
                text:set_color(Color(1, 1, 1, 1))
                icon:set_color(Color(1, 1, 1, 1))
        end
       
       
       
       
       
       
        HUDPlayerPanel.WIDTH = 500
        HUDPlayerPanel.HEIGHT = 75
        HUDPlayerPanel.SUB_PANEL_HORIZONTAL_MARGIN = 3
        HUDPlayerPanel.DEBUG_HIDE = false
       
        function HUDPlayerPanel:init(...)
                HUDPlayerPanel.super.init(self, self.WIDTH, self.HEIGHT, self.SCALE, ...)
               
                self:_create_stamina_panel(self._health_panel:h() * 0.3, self._health_panel:h())
               
                self:set_show_fire_mode(HUDPlayerPanel.SHOW_FIRE_MODE)
               
                self:_arrange_panel()
               
                self._panel:set_bottom(self._parent:h())
                self._panel:set_center_x(self._parent:w() / 2)
        end
       
     function HUDPlayerPanel:_create_health_panel(...)
                HUDPlayerPanel.super._create_health_panel(self, ...)
               
                local radial_stored_health = self._health_panel:bitmap({
                        name = "radial_stored_health",
                        texture = "guis/textures/pd2/hud_health",
                        texture_rect = { 64, 0, -64, 64 },
                        render_template = "VertexColorTexturedRadial",
                        blend_mode = "add",
                        color = Color(0, 0, 0),
                        alpha = 0.5,
                        w = self._health_panel:w(),
                        h = self._health_panel:h(),
                        layer = 3,
                })
        end
 
        function HUDPlayerPanel:set_stored_health(stored_health)
                local radial = self._health_panel:child("radial_stored_health")
                local ratio = stored_health or self._stored_health or 0
                self._stored_health = ratio
                radial:set_color(Color(math.min(ratio, self._stored_health_max), 0, 0))
        end
       
        function HUDPlayerPanel:set_stored_health_max(stored_health_max)
                self._stored_health_max = stored_health_max
                self:set_stored_health()
        end
       
        function HUDPlayerPanel:set_health(data)
                HUDPlayerPanel.super.set_health(self, data)            
                local ratio = data.current / data.total
                local stored_health = self._health_panel:child("radial_stored_health")
                stored_health:set_rotation(-ratio * 360)
                self:set_stored_health_max(1-ratio)
        end
	   
        function HUDPlayerPanel:set_show_fire_mode(status)
                for i = 2, 1, -1 do
                        self._weapons_panel:child("weapons_panel_" .. i):child("firemode_panel"):set_w(status and self._firemode_panel_default_w or 0)
                end
               
                self:_arrange_weapons_panel()
                self:_arrange_panel()
        end
       
        function HUDPlayerPanel:set_show_stamina(status)
                self._stamina_panel:set_w(status and self._stamina_default_w or 0)
                self:_arrange_panel()
        end
       
        function HUDPlayerPanel:effective_height()
                local h = 0
               
                for _, panel in ipairs({ self._health_panel, self._stamina_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel }) do
                        if panel:h() > 0 then
                                h = math.max(h, panel:h())
                        end
                end
               
                return h + (self._carry_panel:visible() and self._carry_panel:h() or 0)
        end
       
        function HUDPlayerPanel:effective_width()
                local w = 0
               
                for _, panel in ipairs({ self._health_panel, self._stamina_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel }) do
                        if panel:w() > 0 then
                                w = w + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
                        end
                end
               
                return math.max(self._carry_panel:w(), w)
        end
       
        function HUDPlayerPanel:_arrange_panel()
                HUDPlayerPanel.super._arrange_panel(self)
               
                local panels = { self._health_panel, self._stamina_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel }
       
                local total_w = 0
                for _, panel in ipairs(panels) do
                        if panel:w() > 0 then
                                total_w = total_w + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
                        end
                end
               
                local x = (self._panel:w() - total_w) / 2
                for _, panel in ipairs(panels) do
                        panel:set_bottom(self._panel:h())
                        panel:set_x(x)
                        if panel:w() > 0 then
                                x = x + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
                        end
                end
               
                self._callsign_panel:set_center(self._health_panel:center())
                self._carry_panel:set_left(self._health_panel:left())
                self._carry_panel:set_bottom(self._health_panel:top())
        end
               
        function HUDPlayerPanel:_create_stamina_panel(width, height)
                self._stamina_default_w = width
                self._stamina_panel = self._panel:panel({
                        name = "stamina_panel",
                        w = width,
                        h = height,
                })
               
                local stamina_bar_outline = self._stamina_panel:bitmap({
                        name = "stamina_bar_outline",
                        texture = "guis/textures/hud_icons",
                        texture_rect = { 252, 240, 12, 48 },
                        color = Color.white,
                        w = width,
                        h = height,
                        layer = 10,
                })
                self._stamina_bar_max_h = stamina_bar_outline:h() * 0.96
                self._default_stamina_color = Color(0.7, 0.8, 1.0)
               
                local stamina_bar = self._stamina_panel:rect({
                        name = "stamina_bar",
                        blend_mode = "normal",
                        color = self._default_stamina_color,
                        alpha = 0.75,
                        h = self._stamina_bar_max_h,
                        w = stamina_bar_outline:w() * 0.9,
                        layer = 5,
                })
                stamina_bar:set_center(stamina_bar_outline:center())
               
                local bar_bg = self._stamina_panel:gradient({
                        layer = 1,
                        gradient_points = { 0, Color.white:with_alpha(0.10), 1, Color.white:with_alpha(0.40) },
                        h = stamina_bar:h(),
                        w = stamina_bar:w(),
                        blend_mode = "sub",
                        orientation = "vertical",
                        layer = 10,
                })
                bar_bg:set_center(stamina_bar:center())
               
                local stamina_threshold = self._stamina_panel:rect({
                        name = "stamina_threshold",
                        color = Color.red,
                        w = stamina_bar:w(),
                        h = 2,
                        layer = 8,
                })
                stamina_threshold:set_center(stamina_bar:center())
        end
 
        function HUDPlayerPanel:set_max_stamina(value)
                if value ~= self._max_stamina then
                        self._max_stamina = value
                        local stamina_bar = self._stamina_panel:child("stamina_bar")
                       
                        local offset = stamina_bar:h() * (tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD / self._max_stamina)
                        self._stamina_panel:child("stamina_threshold"):set_bottom(stamina_bar:bottom() - offset + 1)
                end
        end
 
        function HUDPlayerPanel:set_current_stamina(value)
                local stamina_bar = self._stamina_panel:child("stamina_bar")
                local stamina_bar_outline = self._stamina_panel:child("stamina_bar_outline")
               
                stamina_bar:set_h(self._stamina_bar_max_h * (value / self._max_stamina))
                stamina_bar:set_bottom(0.5 * (stamina_bar_outline:h() + self._stamina_bar_max_h))
                if value <= tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and not self._animating_low_stamina then
                        self._animating_low_stamina = true
                        stamina_bar:animate(callback(self, self, "_animate_low_stamina"), stamina_bar_outline)
                elseif value > tweak_data.player.movement_state.stamina.MIN_STAMINA_THRESHOLD and self._animating_low_stamina then
                        self._animating_low_stamina = nil
                end
        end
 
        function HUDPlayerPanel:_create_weapons_panel(...)
                HUDPlayerPanel.super._create_weapons_panel(self, ...)
               
                for i = 2, 1, -1 do
                        local sub_panel = self._weapons_panel:child("weapons_panel_" .. i)
                       
                        self._firemode_panel_default_w = sub_panel:h() * 0.4
                        local firemode_panel = sub_panel:panel({
                                name = "firemode_panel",
                                layer = 1,
                                w = self._firemode_panel_default_w,
                                h = sub_panel:h(),
                        })
                               
                        local fire_modes = {
                                { name = "auto_fire", abbrev = "A" },
                                { name = "single_fire", abbrev = "S" },
                        }
                        if HUDManager._USE_BURST_MODE then
                                table.insert(fire_modes, 2, { name = "burst_fire", abbrev = "B" })
                        end
                               
                        local bg = firemode_panel:rect({
                                name = "bg",
                                blend_mode = "normal",
                                color = Color.white,
                                h = firemode_panel:h() * math.clamp(#fire_modes * 0.25, 0.25, 1),
                                w = firemode_panel:w() * 0.65,
                                layer = 1,
                        })
                        bg:set_center(firemode_panel:w() / 2, firemode_panel:h() / 2)
 
                        for i, data in ipairs(fire_modes) do
                                local text = firemode_panel:text({
                                        name = data.name,
                                        text = data.abbrev,
                                        color = Color.black,
                                        blend_mode = "normal",
                                        layer = 10,
                                        alpha = 0.75,
                                        w = bg:w(),
                                        h = bg:h() / #fire_modes,
                                        vertical = "center",
                                        align = "center",
                                        font_size = bg:h() / #fire_modes,
                                        font = tweak_data.hud_players.ammo_font
                                })
                                text:set_center(bg:center())
                                text:set_bottom(bg:bottom() - text:h() * (i-1))
                        end
                end
               
                self:recreate_weapon_firemode()
                self:_arrange_weapons_panel()
        end
       
        function HUDPlayerPanel:recreate_weapon_firemode()
                for i = 2, 1, -1 do
                        local weapon = (i == 2) and managers.blackmarket:equipped_primary() or managers.blackmarket:equipped_secondary()
                        local panel = self._weapons_panel:child("weapons_panel_" .. i)
                        local weapon_tweak_data = tweak_data.weapon[weapon.weapon_id]
                        local fire_mode = weapon_tweak_data.FIRE_MODE
                        local can_toggle_firemode = weapon_tweak_data.CAN_TOGGLE_FIREMODE
                        local locked_to_auto = managers.weapon_factory:has_perk("fire_mode_auto", weapon.factory_id, weapon.blueprint)
                        local locked_to_single = managers.weapon_factory:has_perk("fire_mode_single", weapon.factory_id, weapon.blueprint)
 
                        local firemode_panel = panel:child("firemode_panel")
                        local has_single = (fire_mode == "single" or can_toggle_firemode) and not locked_to_auto and true or false
                        firemode_panel:child("single_fire"):set_color(has_single and Color.black or Color(0.6, 0.1, 0.1))
                        local has_auto = (fire_mode == "auto" or can_toggle_firemode) and not locked_to_single and true or false
                        firemode_panel:child("auto_fire"):set_color(has_auto and Color.black or Color(0.6, 0.1, 0.1))
                       
                        local burst_fire = firemode_panel:child("burst_fire")
                        if burst_fire then
                                local has_burst = (weapon_tweak_data.BURST_FIRE or can_toggle_firemode) and not (locked_to_single or locked_to_auto) and (weapon_tweak_data.BURST_FIRE ~= false)
                                burst_fire:set_color(has_burst and Color.black or Color(0.6, 0.1, 0.1))
                        end
                       
                        local default = locked_to_auto and "auto" or locked_to_single and "single" or fire_mode
                        self:set_weapon_firemode(i, default)
                end
        end
       
        function HUDPlayerPanel:set_weapon_id(slot, ...)
                HUDPlayerPanel.super.set_weapon_id(self, slot, ...)
               
                if alive(managers.player:player_unit()) then
                        local burst_fire = self._weapons_panel:child("weapons_panel_" .. slot):child("firemode_panel"):child("burst_fire")
                        local weapon = managers.player:player_unit():inventory():unit_by_selection(slot)
                       
                        if burst_fire and alive(weapon) then
                                local has_burst = weapon:base().can_use_burst_mode and weapon:base():can_use_burst_mode() or false
                                burst_fire:set_color(has_burst and Color.black or Color(0.6, 0.1, 0.1))
                        end
                end
        end
       
        function HUDPlayerPanel:set_weapon_firemode(id, firemode)
                local panel = self._weapons_panel:child("weapons_panel_" .. id)
                local firemode_panel = panel:child("firemode_panel")
                local single_fire = firemode_panel:child("single_fire")
                local auto_fire = firemode_panel:child("auto_fire")
                local burst_fire = firemode_panel:child("burst_fire")
               
                local active_alpha = 1
                local inactive_alpha = 0.65
               
                if firemode == "single" then
                        single_fire:set_alpha(active_alpha)
                        single_fire:set_text("[S]")
                        auto_fire:set_alpha(inactive_alpha)
                        auto_fire:set_text("A")
                        if burst_fire then
                                burst_fire:set_text("B")
                                burst_fire:set_alpha(inactive_alpha)
                        end
                elseif firemode == "auto" then
                        auto_fire:set_alpha(active_alpha)
                        auto_fire:set_text("[A]")
                        single_fire:set_alpha(inactive_alpha)
                        single_fire:set_text("S")
                        if burst_fire then
                                burst_fire:set_text("B")
                                burst_fire:set_alpha(inactive_alpha)
                        end
                elseif firemode == "burst" then
                        burst_fire:set_alpha(active_alpha)
                        burst_fire:set_text("[B]")
                        auto_fire:set_alpha(inactive_alpha)
                        auto_fire:set_text("A")
                        single_fire:set_alpha(inactive_alpha)
                        single_fire:set_text("S")
                end
        end
 
        function HUDPlayerPanel:set_weapon_firemode_burst(id)
                self:set_weapon_firemode(id, "burst")
        end
       
        function HUDPlayerPanel:_create_carry_panel()
                HUDPlayerPanel.super._create_carry_panel(self, self._panel:h() - self._health_panel:h())
        end
       
        function HUDPlayerPanel:set_carry_info(...)
                HUDPlayerPanel.super.set_carry_info(self, ...)
               
                local text = self._carry_panel:child("text")
                local icon = self._carry_panel:child("icon")
                icon:set_left(0)
                text:set_left(icon:right() + 2)
                self._carry_panel:set_w(self._show_carry_info and (text:w() + icon:w() + 2) or 0)
                self._carry_panel:set_center_x(self._panel:w() / 2)
               
                --self:_arrange_panel()
        end
       
        function HUDPlayerPanel:teammate_progress(...)
                --Why does this happen?
        end
       
        function HUDPlayerPanel:set_cheater(state)
       
        end
       
        function HUDPlayerPanel:add_panel(...)
                if not HUDPlayerPanel.DEBUG_HIDE then
                        HUDPlayerPanel.super.add_panel(self, ...)
                end
        end
       
        function HUDPlayerPanel:remove_panel()
                HUDPlayerPanel.super.remove_panel(self)
               
                self._stamina_panel:child("stamina_bar"):stop()
        end
       
        function HUDPlayerPanel:_animate_low_stamina(stamina_bar, stamina_bar_outline)
                local target = Color(1.0, 0.1, 0.1)
                local bar = self._default_stamina_color
                local border = Color.white
       
                while self._animating_low_stamina do
                        local t = 0
                        while t <= 0.5 do
                                t = t + coroutine.yield()
                                local ratio = 0.5 + 0.5 * math.sin(t * 720)
                                stamina_bar:set_color(Color(
                                        bar.r + (target.r - bar.r) * ratio,
                                        bar.g + (target.g - bar.g) * ratio,
                                        bar.b + (target.b - bar.b) * ratio))
                                stamina_bar_outline:set_color(Color(
                                        border.r + (target.r - border.r) * ratio,
                                        border.g + (target.g - border.g) * ratio,
                                        border.b + (target.b - border.b) * ratio))
                        end
                end
               
                stamina_bar:set_color(bar)
                stamina_bar_outline:set_color(border)
        end
       
        function HUDPlayerPanel:set_name(teammate_name)
                self._name = teammate_name
        end
       
       
       
       
       
       
        HUDTeammatePanel.WIDTH = 400
        HUDTeammatePanel.HEIGHT = 65
        HUDTeammatePanel.SUB_PANEL_HORIZONTAL_MARGIN = 2
        HUDTeammatePanel.DEBUG_HIDE = false
       
        HUDTeammatePanel._INTERACTION_TEXTS = {
                big_computer_server = "USING COMPUTER",
        --[[
                ammo_bag = "Using ammo bag",
                c4_bag = "Taking C4",
                c4_mission_door = "Planting C4 (equipment)",
                c4_x1_bag = "Taking C4",
                connect_hose = "Connecting hose",
                crate_loot = "Opening crate",
                crate_loot_close = "Closing crate",
                crate_loot_crowbar = "Opening crate",
                cut_fence = "Cutting fence",
                doctor_bag = "Using doctor bag",
                drill = "Placing drill",
                drill_jammed = "Repairing drill",
                drill_upgrade = "Upgrading drill",
                ecm_jammer = "Placing ECM jammer",
                first_aid_kit = "Using first aid kit",
                free = "Uncuffing",
                grenade_briefcase = "Taking grenade",
                grenade_crate = "Opening grenade case",
                hack_suburbia_jammed = "Resuming hack",
                hold_approve_req = "Approving request",
                hold_close = "Closing door",
                hold_close_keycard = "Closing door (keycard)",
                hold_download_keys = "Starting hack",
                hold_hack_comp = "Starting hack",
                hold_open = "Opening door",
                hold_open_bomb_case = "Opening bomb case",
                hold_pku_disassemble_cro_loot = "Disassembling bomb",
                hold_remove_armor_plating = "Removing plating",
                hold_remove_ladder = "Taking ladder",
                hold_take_server_axis = "Taking server",
                hostage_convert = "Converting enemy",
                hostage_move = "Moving hostage",
                hostage_stay = "Moving hostage",
                hostage_trade = "Trading hostage",
                intimidate = "Cable tying civilian",
                open_train_cargo_door = "Opening door",
                pick_lock_easy_no_skill = "Picking lock",
                requires_cable_ties = "Cable tying civilian",
                revive = "Reviving",
                sentry_gun_refill = "Refilling sentry gun",
                shaped_charge_single = "Planting C4 (deployable)",
                shaped_sharge = "Planting C4 (deployable)",
                shape_charge_plantable = "Planting C4 (equipment)",
                shape_charge_plantable_c4_1 = "Planting C4 (equipment)",
                shape_charge_plantable_c4_x1 = "Planting C4 (equipment)",
                trip_mine = "Placing trip mine",
                uload_database_jammed = "Resuming hack",
                use_ticket = "Using ticket",
                votingmachine2 = "Starting hack",
                votingmachine2_jammed = "Resuming hack",
                methlab_caustic_cooler = "Cooking meth (caustic soda)",
                methlab_gas_to_salt = "Cooking meth (hydrogen chloride)",
                methlab_bubbling = "Cooking meth (muriatic acid)",
                money_briefcase = "Opening briefcase",
                pku_barcode_downtown = "Taking barcode (downtown)",
                pku_barcode_edgewater = "Taking barcode (?)",   --TODO: Location
                gage_assignment = "Taking courier package",
                stash_planks = "Boarding window",
                stash_planks_pickup = "Taking planks",
                taking_meth = "Bagging loot",
                hlm_connect_equip = "Connecting cable",
        ]]
        }
       
        function HUDTeammatePanel:init(...)
                HUDTeammatePanel.super.init(self, self.WIDTH, self.HEIGHT, self.SCALE, ...)
               
                local name_height = self._panel:h() - self._health_panel:h()
                self:_create_name_panel(math.max(self:effective_width(), name_height * 4), name_height)
                self:_create_interact_panel(self._health_panel:h())
               
                self:set_show_name(self.SHOW_NAME)
               
                self:_arrange_panel()
 
                --self._panel:set_bottom(self._parent:h() - (self._id - (self._id > 4 and 2 or 1)) * self._panel:h())
                --self._panel:set_x(0)
        end
       
        function HUDTeammatePanel:set_show_name(status)
                self._show_name = status
                self._name_panel:set_h(status and self._default_name_height or 0)
                managers.hud:restack_team_panels()
        end
       
        function HUDTeammatePanel:effective_height()
                local h = 0
                for _, panel in ipairs({ self._health_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
                        if panel then
                                h = math.max(panel:h(), h)
                        end
                end
               
                return h + (self._name_panel and self._name_panel:h() or 0)
        end
       
        function HUDTeammatePanel:effective_width()
                local w = 0
                for _, panel in ipairs({ self._health_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
                        if panel then
                                w = w + panel:w()
                        end
                end
               
                return math.max(w, self._name_panel and self._name_panel:w() or 0)
        end
       
        function HUDTeammatePanel:_arrange_panel()
                HUDTeammatePanel.super._arrange_panel(self)
       
                local x = 0
                local panels = { self._health_panel, self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }
                for _, panel in ipairs(panels) do
                        if panel then
                                panel:set_bottom(self._panel:h())
                                panel:set_x(x)
                                if panel:w() > 0 then
                                        x = x + panel:w() + self.SUB_PANEL_HORIZONTAL_MARGIN
                                end
                        end
                end
               
                if self._name_panel then
                        self._name_panel:set_bottom(self._health_panel:top())
                        self._name_panel:set_x(0)
                end
                if self._carry_panel then
                        self._carry_panel:set_center_y(self._panel:h() / 2)
                end
                if self._interact_panel then
                        self._interact_panel:set_left(self._health_panel:right())
                end
        end
       
        function HUDTeammatePanel:_create_name_panel(width, height)
                self._default_name_height = height
                self._name_panel = self._panel:panel({
                        name = "name_panel",
                        w = width,
                        h = height,
                })             
               
                local text = self._name_panel:text({
                        name = "name",
                        text = tostring(self._id),
                        layer = 1,
                        color = Color.white,
                        --align = "left",
                        align = "center",
                        vertical = "center",
                        w = self._name_panel:w(),
                        h = self._name_panel:h(),
                        font_size = self._name_panel:h(),
                        font = tweak_data.hud_players.name_font
                })
        end
 
        function HUDTeammatePanel:_create_weapons_panel(...)
                HUDTeammatePanel.super._create_weapons_panel(self, ...)
                self:_arrange_weapons_panel()
        end
       
        function HUDTeammatePanel:_create_carry_panel()
                HUDTeammatePanel.super._create_carry_panel(self, self._panel:h() / 2)
               
                local text = self._carry_panel:child("text")
                local icon = self._carry_panel:child("icon")
               
                icon:set_w(self._carry_panel:h() / 2)
                icon:set_h(icon:w())
                text:set_h(self._carry_panel:h() / 2)
                text:set_font_size(text:h())
        end
       
        function HUDTeammatePanel:set_carry_info(...)
                HUDTeammatePanel.super.set_carry_info(self, ...)
               
                local text = self._carry_panel:child("text")
                local icon = self._carry_panel:child("icon")
               
                self._carry_panel:set_w(self._show_carry_info and math.max(text:w(), icon:w()) or 0)
                self._carry_panel:set_center_y(self._panel:h() / 2)
                icon:set_bottom((icon:h() + text:h()) / 2)
                icon:set_center_x(self._carry_panel:w() / 2)
                text:set_top(self._carry_panel:h() - (icon:h() + text:h()) / 2)
                text:set_center_x(self._carry_panel:w() / 2)
               
                self:_arrange_panel()
        end
       
        function HUDTeammatePanel:_create_interact_panel(height)
                self._interact_panel = self._panel:panel({
                        name = "interact_panel",
                        layer = 0,
                        visible = false,
                        alpha = 0,
                        w = 0,
                        h = height,
                })
                self._interact_panel:set_bottom(self._panel:h())
               
                self._interact_panel:rect({
                        name = "bg",
                        blend_mode = "normal",
                        color = Color.black,
                        alpha = 0.25,
                        h = self._interact_panel:h(),
                        w = self._interact_panel:w(),
                        layer = -1,
                })
 
                local interact_text = self._interact_panel:text({
                        name = "interact_text",
                        layer = 10,
                        color = Color.white,
                        w = self._interact_panel:w(),
                        h = self._interact_panel:h() * 0.5,
                        vertical = "center",
                        align = "center",
                        blend_mode = "normal",
                        font_size = self._interact_panel:h() * 0.3,
                        font = tweak_data.hud_players.name_font
                })
                interact_text:set_top(0)
               
                local interact_bar_outline = self._interact_panel:bitmap({
                        name = "outline",
                        texture = "guis/textures/hud_icons",
                        texture_rect = { 252, 240, 12, 48 },
                        w = self._interact_panel:h() * 0.5,
                        h = self._interact_panel:w() * 0.75,
                        layer = 10,
                        rotation = 90
                })
               
                self._interact_bar_max_width = interact_bar_outline:h() * 0.97
 
                local interact_bar = self._interact_panel:gradient({
                        name = "interact_bar",
                        blend_mode = "normal",
                        alpha = 0.75,
                        layer = 5,
                        h = interact_bar_outline:w() * 0.8,
                        w = self._interact_bar_max_width,
                })
               
                local interact_bar_bg = self._interact_panel:rect({
                        name = "interact_bar_bg",
                        blend_mode = "normal",
                        color = Color.black,
                        alpha = 1.0,
                        h = interact_bar_outline:w(),
                        w = interact_bar_outline:h(),
                        layer = 0,
                })
               
                local interact_timer = self._interact_panel:text({
                        name = "interact_timer",
                        layer = 10,
                        color = Color.white,
                        w = interact_bar:w(),
                        h = interact_bar:h(),
                        vertical = "center",
                        align = "center",
                        blend_mode = "normal",
                        font_size = interact_bar:h(),
                        font = tweak_data.hud_players.name_font
                })
        end
       
        function HUDTeammatePanel:_adjust_interact_panel_size()
                local w = math.max(self:effective_width() - self._health_panel:w(), self._interact_panel:h() * 4)
               
                if w ~= self._interact_panel:w() then
                        self._interact_panel:set_w(w)
                        self._interact_panel:child("bg"):set_w(w)
                        self._interact_panel:child("interact_text"):set_w(w)
                       
                        local interact_bar_outline = self._interact_panel:child("outline")
                        interact_bar_outline:set_h(w * 0.75)
                        interact_bar_outline:set_center_x(w / 2)
                        interact_bar_outline:set_bottom(self._interact_panel:h() + interact_bar_outline:h() / 2 - interact_bar_outline:w() / 2)
                        self._interact_bar_max_width = interact_bar_outline:h() * 0.97
                       
                        local interact_bar = self._interact_panel:child("interact_bar")
                        interact_bar:set_w(self._interact_bar_max_width)
                        interact_bar:set_center(interact_bar_outline:center())
                       
                        local interact_bar_bg = self._interact_panel:child("interact_bar_bg")
                        interact_bar_bg:set_w(interact_bar_outline:h())
                        interact_bar_bg:set_center(interact_bar:center())
                       
                        local interact_timer = self._interact_panel:child("interact_timer")
                        interact_timer:set_w(interact_bar:w())
                        interact_timer:set_center(interact_bar:center())
                end
        end
       
        function HUDTeammatePanel:teammate_progress(enabled, tweak_data_id, timer, success)
                self._interact_panel:stop()
               
                if not enabled and self._interact_panel:visible() then
                        self._interact_panel:animate(callback(self, self, "_animate_interact_timer_complete"), success)
                end
               
                if enabled and HUDTeammatePanel.SHOW_INTERACTIONS and (timer > HUDTeammatePanel.SHOW_INTERACTIONS) then
                        local text = ""
                        if tweak_data_id then
                                local action_text_id = tweak_data.interaction[tweak_data_id] and tweak_data.interaction[tweak_data_id].action_text_id or "hud_action_generic"
                                text = HUDTeammatePanel._INTERACTION_TEXTS[tweak_data_id] or action_text_id and managers.localization:text(action_text_id)
                        end
                       
                        self._interact_panel:child("interact_text"):set_text(string.format("%s (%.1fs)", utf8.to_upper(text), timer))
                        self._interact_panel:animate(callback(self, self, "_animate_interact_timer"), timer)
                end
        end
 
        function HUDTeammatePanel:set_cheater(state)
                self._name_panel:child("name"):set_color(state and tweak_data.screen_colors.pro_color or Color.white)
        end
       
        function HUDTeammatePanel:add_panel(...)
                if not HUDTeammatePanel.DEBUG_HIDE then
                        HUDTeammatePanel.super.add_panel(self, ...)
                end
        end
       
        function HUDTeammatePanel:remove_panel()
                HUDTeammatePanel.super.remove_panel(self)
               
                --TODO
                --self:teammate_progress(false)
        end
       
        function HUDTeammatePanel:set_callsign(id)
                HUDTeammatePanel.super.set_callsign(self, id)
                self._name_panel:child("name"):set_color((tweak_data.chat_colors[id] or Color.white):with_alpha(1))
                self._callsign_panel:child("callsign"):set_color(tweak_data.chat_colors[id]:with_alpha(1))
        end
       
        function HUDTeammatePanel:set_ai(ai)
                HUDTeammatePanel.super.set_ai(self, ai)
               
                self._interact_panel:stop()
                self._interact_panel:set_visible(false)
                self._name_panel:child("name"):set_color((not ai and tweak_data.chat_colors[self._id] or Color.white):with_alpha(1))
        end
       
        function HUDTeammatePanel:set_name(teammate_name)
                if self._name ~= teammate_name then
                        self._name = teammate_name
                        self._name_panel:stop()
                       
                        local text = self._name_panel:child("name")
                        text:set_left(0)

						local experience = ""
						if self:peer_id() then
							local peer = managers.network:session():peer(self:peer_id())
							experience = " (" .. (peer:rank() > 0 and managers.experience:rank_string(peer:rank()) .. "-" or "") .. peer:level() .. ")"
						end
						
                        text:set_text(teammate_name)
                        local _, _, w, _ = text:text_rect()
                        w = w + 5
                        text:set_w(w)
                        if w > self._name_panel:w() then
                                self._name_panel:animate(callback(self, self, "_animate_name_label"), w - self._name_panel:w())
                        end
                end
        end
       
       
        function HUDTeammatePanel:_animate_name_label(panel, width)
                local t = 0
                local text = self._name_panel:child("name")
               
                while true do
                        t = t + coroutine.yield()
                        text:set_left(width * (math.sin(90 + t * HUDTeammate._NAME_ANIMATE_SPEED) * 0.5 - 0.5))
                end
        end
       
        function HUDTeammatePanel:_animate_interact_timer(panel, timer)
                self:_adjust_interact_panel_size()
               
                local bar = panel:child("interact_bar")
                local text = panel:child("interact_timer")
                local outline = panel:child("outline")
                text:set_size(self._interact_bar_max_width, bar:h())
                text:set_font_size(text:h())
                text:set_color(Color.white)
                text:set_alpha(1)
                text:set_center(outline:center())
               
                self._interact_panel:set_visible(true)
                self._interact_panel:set_alpha(0)
               
                for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
                        if panel then
                                panel:set_alpha(1)
                        end
                end
               
                local b = 0
                local g_max = 0.9
                local g_min = 0.1
                local r_max = 0.9
                local r_min = 0.1              
               
                local T = 0.5
                local t = 0
                while timer > t do
                        if t < T then
                                for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
                                        if panel then
                                                panel:set_alpha(1-t/T)
                                        end
                                end
                                self._interact_panel:set_alpha(t/T)
                        end
               
                        local time_left = timer - t
                        local r = t / timer
                        bar:set_w(self._interact_bar_max_width * r)
                        if r < 0.5 then
                                local green = math.clamp(r * 2, 0, 1) * (g_max - g_min) + g_min
                                bar:set_gradient_points({ 0, Color(r_max, g_min, b), 1, Color(r_max, green, b) })
                        else
                                local red = math.clamp(1 - (r - 0.5) * 2, 0, 1) * (r_max - r_min) + r_min
                                bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5/r, Color(r_max, g_max, b), 1, Color(red, g_max, b) })
                        end
                        --bar:set_gradient_points({0, Color(0.9, 0.1, 0.1), 1, Color((1-r) * 0.8 + 0.1, r * 0.8 + 0.1, 0.1)})
                        text:set_text(string.format("%.1fs", time_left))
                        t = t + coroutine.yield()
                end
               
                bar:set_w(self._interact_bar_max_width)
                bar:set_gradient_points({ 0, Color(r_max, g_min, b), 0.5, Color(r_max, g_max, b), 1, Color(r_min, g_max, b) })
                --bar:set_gradient_points({ 0, Color(0.9, 0.1, 0.1), 1, Color(0.1, 0.9, 0.1) })
        end
       
        function HUDTeammatePanel:_animate_interact_timer_complete(panel, success)
                local text = panel:child("interact_timer")
                local h = text:h()
                local w = text:w()
                local x = text:center_x()
                local y = text:center_y()
                text:set_color(success and Color.green or Color.red)
               
                for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
                        if panel then
                                panel:set_alpha(0)
                        end
                end
                self._interact_panel:set_alpha(1)
               
                if success then
                        text:set_text("DONE")
                end
               
                local T = 1
                local t = 0
                while t < T do
                        local r = math.sin(t/T*90)
                        text:set_size(w * (1 + r * 2), h * (1 + r * 2))
                        text:set_font_size(text:h())
                        text:set_center(x, y)
 
                        for _, panel in ipairs({ self._weapons_panel, self._equipment_panel, self._special_equipment_panel, self._carry_panel }) do
                                if panel then
                                        panel:set_alpha(t/T)
                                end
                        end
                        self._interact_panel:set_alpha(1-t/T)
                        t = t + coroutine.yield()
                end
               
                self._interact_panel:set_visible(false)
                coroutine.yield()       --Prevents text flashing
                text:set_text("")
                text:set_color(Color.white)
                text:set_size(self._interact_bar_max_width, h)
                text:set_font_size(text:h())
                text:set_center(x, y)
        end
 
       
       
       
       
       
       
        HUDManager.TEAM_PANEL_SPACING = 1
       
        local _create_teammates_panel_original = HUDManager._create_teammates_panel
        local add_teammate_panel_original = HUDManager.add_teammate_panel
        local remove_teammate_panel_original = HUDManager.remove_teammate_panel
        local set_mugshot_voice_original = HUDManager.set_mugshot_voice
        local set_teammate_callsign_original = HUDManager.set_teammate_callsign
        local set_teammate_name_original = HUDManager.set_teammate_name
        local mark_cheater_original = HUDManager.mark_cheater
        local set_stamina_value_original = HUDManager.set_stamina_value
        local set_max_stamina_original = HUDManager.set_max_stamina
        local set_teammate_health_original = HUDManager.set_teammate_health
        local set_teammate_armor_original = HUDManager.set_teammate_armor
        local set_teammate_custom_radial_original = HUDManager.set_teammate_custom_radial
        local set_teammate_condition_original = HUDManager.set_teammate_condition
        local start_teammate_timer_original = HUDManager.start_teammate_timer
        local pause_teammate_timer_original = HUDManager.pause_teammate_timer
        local stop_teammate_timer_original = HUDManager.stop_teammate_timer
        local add_weapon_original = HUDManager.add_weapon
        local set_teammate_weapon_firemode_original = HUDManager.set_teammate_weapon_firemode
        local _set_teammate_weapon_selected_original = HUDManager._set_teammate_weapon_selected
        local set_teammate_ammo_amount_original = HUDManager.set_teammate_ammo_amount
        local set_deployable_equipment_original = HUDManager.set_deployable_equipment
        local set_teammate_deployable_equipment_amount_original = HUDManager.set_teammate_deployable_equipment_amount
        local set_teammate_grenades_original = HUDManager.set_teammate_grenades
        local set_teammate_grenades_amount_original = HUDManager.set_teammate_grenades_amount
        local set_cable_tie_original = HUDManager.set_cable_tie
        local set_cable_ties_amount_original = HUDManager.set_cable_ties_amount
        local add_teammate_special_equipment_original = HUDManager.add_teammate_special_equipment
        local remove_teammate_special_equipment_original = HUDManager.remove_teammate_special_equipment
        local set_teammate_special_equipment_amount_original = HUDManager.set_teammate_special_equipment_amount
        local clear_player_special_equipments_original = HUDManager.clear_player_special_equipments
        local set_teammate_carry_info_original = HUDManager.set_teammate_carry_info
        local remove_teammate_carry_info_original = HUDManager.remove_teammate_carry_info
        local teammate_progress_original = HUDManager.teammate_progress
		local set_stored_health_max_original = HUDManager.set_stored_health_max
		local set_stored_health_original = HUDManager.set_stored_health
		
		        function HUDManager:set_stored_health(...)
                self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_stored_health(...)
                return set_stored_health_original(self, ...)
        end
       
        function HUDManager:set_stored_health_max(...)
                self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_stored_health_max(...)
                return set_stored_health_max_original(self, ...)
        end	   
	   
        function HUDManager:_create_teammates_panel(hud, ...)
                _create_teammates_panel_original(self, hud, ...)
                local teammates_panel = hud.panel:child("teammates_panel")
                teammates_panel:hide()
               
                local hud = hud or managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
                self._hud.teammate_panels_data_custom = self._hud.teammate_panels_data_custom or {}
                self._teammate_panels_custom = {}
               
                if hud.panel:child("teammates_panel_custom") then
                        hud.panel:remove(hud.panel:child("teammates_panel_custom"))
                end
               
                local teammates_panel_custom = hud.panel:panel({
                        name = "teammates_panel_custom",
                        h = hud.panel:h(),
                        w = hud.panel:w(),
                })
 
                --local num_panels = CriminalsManager and CriminalsManager.MAX_NR_CRIMINALS or 4
                --for i = 1, math.max(num_panels, HUDManager.PLAYER_PANEL) do
                for i = 1, 4, 1 do
                        local is_player = i == HUDManager.PLAYER_PANEL
                        self._hud.teammate_panels_data_custom[i] = {
                                taken = false,--is_player,--false and is_player,        --TODO: The fuck is up with this value?
                                special_equipments = {},
                        }
                       
                        local teammate = is_player and HUDPlayerPanel:new(i, teammates_panel_custom) or HUDTeammatePanel:new(i, teammates_panel_custom)
                        table.insert(self._teammate_panels_custom, teammate)
                       
                        if is_player then
                                teammate:add_panel()
                        end
                end
        end
 
        function HUDManager:add_teammate_panel(character_name, player_name, ai, peer_id, ...)
                for i, data in ipairs(self._hud.teammate_panels_data_custom) do
                        if not data.taken then
                                self._teammate_panels_custom[i]:add_panel()
                                self._teammate_panels_custom[i]:set_peer_id(peer_id)
                                self._teammate_panels_custom[i]:set_ai(ai)
                                data.taken = true
                                break
                        end
                end
               
                self:restack_team_panels()
               
                return add_teammate_panel_original(self, character_name, player_name, ai, peer_id, ...)
        end
       
        function HUDManager:remove_teammate_panel(id, ...)
                self._teammate_panels_custom[id]:remove_panel()
                self._hud.teammate_panels_data_custom[id].taken = false
               
                --TODO: WTF is this stuff about?
                --[[
                local is_ai = self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._ai
                if self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._peer_id and self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._peer_id ~= managers.network:session():local_peer():id() or is_ai then
                        local peer_id = self._teammate_panels_custom[HUDManager.PLAYER_PANEL]._peer_id
                        self:remove_teammate_panel(HUDManager.PLAYER_PANEL)
                        if is_ai then
                                local character_name = managers.criminals:character_name_by_panel_id(HUDManager.PLAYER_PANEL)
                                local name = managers.localization:text("menu_" .. character_name)
                                local panel_id = self:add_teammate_panel(character_name, name, true, nil)
                                managers.criminals:character_data_by_name(character_name).panel_id = panel_id
                        else
                                local character_name = managers.criminals:character_name_by_peer_id(peer_id)
                                local panel_id = self:add_teammate_panel(character_name, managers.network:session():peer(peer_id):name(), false, peer_id)
                                managers.criminals:character_data_by_name(character_name).panel_id = panel_id
                        end
                end
                ]]
                managers.hud._teammate_panels_custom[HUDManager.PLAYER_PANEL]:add_panel()
                self:restack_team_panels()
               
                return remove_teammate_panel_original(self, id, ...)
        end
       
        function HUDManager:set_mugshot_voice(id, active, ...)
                local panel_id
                for _, data in pairs(managers.criminals:characters()) do
                        if data.data.mugshot_id == id then
                                panel_id = data.data.panel_id
                                break
                        end
                end
 
                if panel_id and panel_id ~= HUDManager.PLAYER_PANEL then
                        self._teammate_panels_custom[panel_id]:set_voice_com(active)
                end
               
                return set_mugshot_voice_original(self, id, active, ...)
        end
       
        function HUDManager:set_teammate_callsign(i, ...)
                self._teammate_panels_custom[i]:set_callsign(...)
                return set_teammate_callsign_original(self, i, ...)
        end
       
        function HUDManager:set_teammate_name(i, ...)
                self._teammate_panels_custom[i]:set_name(...)
                return set_teammate_name_original(self, i, ...)
        end
 
        function HUDManager:mark_cheater(peer_id, ...)
                for i, data in ipairs(self._hud.teammate_panels_data) do
                        if self._teammate_panels_custom[i]:peer_id() == peer_id then
                                self._teammate_panels_custom[i]:set_cheater(true)
                                break
                        end
                end
               
                return mark_cheater_original(self, peer_id, ...)
        end
 
        function HUDManager:set_stamina_value(...)
                self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_current_stamina(...)
                return set_stamina_value_original(self, ...)
        end
       
        function HUDManager:set_max_stamina(...)
                self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_max_stamina(...)
                return set_max_stamina_original(self, ...)
        end
 
        function HUDManager:set_teammate_health(i, ...)
                self._teammate_panels_custom[i]:set_health(...)
                return set_teammate_health_original(self, i, ...)
        end
       
        function HUDManager:set_teammate_armor(i, ...)
                self._teammate_panels_custom[i]:set_armor(...)
                return set_teammate_armor_original(self, i, ...)
        end
       
        function HUDManager:set_teammate_custom_radial(i, ...)
                self._teammate_panels_custom[i]:set_custom_radial(...)
                return set_teammate_custom_radial_original(self, i, ...)
        end
       
        function HUDManager:set_teammate_condition(i, ...)
                self._teammate_panels_custom[i]:set_condition(...)
                return set_teammate_condition_original(self, i, ...)
        end
       
        function HUDManager:start_teammate_timer(i, ...)
                self._teammate_panels_custom[i]:start_timer(...)
                return start_teammate_timer_original(self, i, ...)
        end
       
        function HUDManager:pause_teammate_timer(i, ...)
                self._teammate_panels_custom[i]:set_pause_timer(...)
                return pause_teammate_timer_original(self, i, ...)
        end
       
        function HUDManager:stop_teammate_timer(i, ...)
                self._teammate_panels_custom[i]:stop_timer(...)
                return stop_teammate_timer_original(self, i, ...)
        end
       
        function HUDManager:add_weapon(data, ...)
                local selection_index = data.inventory_index
                local weapon_id = data.unit:base().name_id
                local silencer = data.unit:base():got_silencer()
                self:set_teammate_weapon_id(HUDManager.PLAYER_PANEL, selection_index, weapon_id, silencer)
 
                return add_weapon_original(self, data, ...)
        end
       
        function HUDManager:set_teammate_weapon_firemode(i, ...)
                self._teammate_panels_custom[i]:set_weapon_firemode(...)
                return set_teammate_weapon_firemode_original(self, i, ...)
        end
       
        function HUDManager:_set_teammate_weapon_selected(i, ...)
                self._teammate_panels_custom[i]:set_weapon_selected(...)
                return _set_teammate_weapon_selected_original(self, i, ...)
        end
       
        function HUDManager:set_teammate_ammo_amount(i, ...)
                self._teammate_panels_custom[i]:set_ammo_amount_by_type(...)
                return set_teammate_ammo_amount_original(self, i, ...)
        end
 
        function HUDManager:set_deployable_equipment(i, ...)
                self._teammate_panels_custom[i]:set_deployable_equipment(...)
                return set_deployable_equipment_original(self, i, ...)
        end
 
        function HUDManager:set_teammate_deployable_equipment_amount(i, ...)
                self._teammate_panels_custom[i]:set_deployable_equipment_amount(...)
                return set_teammate_deployable_equipment_amount_original(self, i, ...)
        end
 
        function HUDManager:set_teammate_grenades(i, ...)
                self._teammate_panels_custom[i]:set_grenades(...)
                return set_teammate_grenades_original(self, i, ...)
        end
 
        function HUDManager:set_teammate_grenades_amount(i, ...)
                self._teammate_panels_custom[i]:set_grenades_amount(...)
                return set_teammate_grenades_amount_original(self, i, ...)
        end    
 
        function HUDManager:set_cable_tie(i, ...)
                self._teammate_panels_custom[i]:set_cable_tie(...)
                return set_cable_tie_original(self, i, ...)
        end
 
        function HUDManager:set_cable_ties_amount(i, ...)
                self._teammate_panels_custom[i]:set_cable_ties_amount(...)
                return set_cable_ties_amount_original(self, i, ...)
        end
 
        function HUDManager:add_teammate_special_equipment(i, ...)
                self._teammate_panels_custom[i]:add_special_equipment(...)
                return add_teammate_special_equipment_original(self, i, ...)
        end
 
        function HUDManager:remove_teammate_special_equipment(i, ...)
                self._teammate_panels_custom[i]:remove_special_equipment(...)
                return remove_teammate_special_equipment_original(self, i, ...)
        end
 
        function HUDManager:set_teammate_special_equipment_amount(i, ...)
                self._teammate_panels_custom[i]:set_special_equipment_amount(...)
                return set_teammate_special_equipment_amount_original(self, i, ...)
        end
 
        function HUDManager:clear_player_special_equipments(...)
                self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:clear_special_equipment(...)
                return clear_player_special_equipments_original(self,  ...)
        end
       
        function HUDManager:set_teammate_carry_info(i, ...)
                self._teammate_panels_custom[i]:set_carry_info(...)
                return set_teammate_carry_info_original(self, i, ...)
        end
 
        function HUDManager:remove_teammate_carry_info(i, ...)
                self._teammate_panels_custom[i]:remove_carry_info()
                return remove_teammate_carry_info_original(self, i, ...)
        end
 
        function HUDManager:teammate_progress(peer_id, type_index, ...)
                local character_data = managers.criminals:character_data_by_peer_id(peer_id)
                if character_data then
                        self._teammate_panels_custom[character_data.panel_id]:teammate_progress(...)
                end
               
                return teammate_progress_original(self, peer_id, type_index, ...)
        end
 
       
        function HUDManager:set_teammate_weapon_id(i, ...)
                self._teammate_panels_custom[i]:set_weapon_id(...)
        end
       
        function HUDManager:set_teammate_weapon_firemode_burst(id)
                self._teammate_panels_custom[HUDManager.PLAYER_PANEL]:set_weapon_firemode_burst(id)
        end
       
        function HUDManager:restack_team_panels()
                local offset = 0
                for i, data in ipairs(self._hud.teammate_panels_data_custom) do
                        if data.taken and i ~= HUDManager.PLAYER_PANEL then
                                local panel = self._teammate_panels_custom[i]:panel()
                                local h = self._teammate_panels_custom[i]:effective_height()
                                panel:set_bottom(panel:parent():h() - offset)
                                offset = offset + h + HUDManager.TEAM_PANEL_SPACING
                        end
                end
        end


if RequiredScript == "lib/managers/hud/hudassaultcorner" then
	
	
        local init_original = HUDAssaultCorner.init
 
        function HUDAssaultCorner:init(...)
                init_original(self, ...)
               
                local assault_panel = self._hud_panel:child("assault_panel")
                assault_panel:set_right(self._hud_panel:w() / 2 + 133)
                local buffs_panel = self._hud_panel:child("buffs_panel")
                buffs_panel:set_x(assault_panel:left() + self._bg_box:left() - 3 - 200)
               
                local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
                point_of_no_return_panel:set_right(self._hud_panel:w() / 2 + 133)
               
                local casing_panel = self._hud_panel:child("casing_panel")
                casing_panel:set_right(self._hud_panel:w() / 2 + 133)
               
                local hostages_panel = self._hud_panel:child("hostages_panel")
                hostages_panel:set_alpha(0)
        end

	function HUDAssaultCorner:sync_start_assault(data)
		if self._point_of_no_return then
			return
		end

		if managers.job:current_difficulty_stars() > 0 then
			local ids_risk = Idstring("risk")
			self:_start_assault({
				"hud_assault_assault",
				"hud_assault_end_line",
				ids_risk,
				"hud_assault_end_line",
				"hud_assault_assault",
				"hud_assault_end_line",
				ids_risk,
				"hud_assault_end_line"
			})
		else
			self:_start_assault({
				"hud_assault_assault",
				"hud_assault_end_line",
				"hud_assault_assault",
				"hud_assault_end_line",
				"hud_assault_assault",
				"hud_assault_end_line"
			})
		end
	end

	function HUDAssaultCorner:show_point_of_no_return_timer()
		local delay_time = self._assault and 1.2 or 0
		self:_end_assault()
		local point_of_no_return_panel = self._hud_panel:child("point_of_no_return_panel")
		point_of_no_return_panel:stop()
		point_of_no_return_panel:animate(callback(self, self, "_animate_show_noreturn"), delay_time)
		self._point_of_no_return = true
	end

	function HUDAssaultCorner:hide_point_of_no_return_timer()
		self._noreturn_bg_box:stop()
		self._hud_panel:child("point_of_no_return_panel"):set_visible(false)
		self._point_of_no_return = false
	end

	function HUDAssaultCorner:set_control_info(...) end
	function HUDAssaultCorner:show_casing(...) end
	function HUDAssaultCorner:hide_casing(...) end
	
end
	
if RequiredScript == "lib/managers/hud/hudobjectives" then
	
	
	HUDObjectives._TEXT_MARGIN = 8

	function HUDObjectives:init(hud)
		if hud.panel:child("objectives_panel") then
			hud.panel:remove(self._panel:child("objectives_panel"))
		end

		self._panel = hud.panel:panel({
			visible = false,
			name = "objectives_panel",
			h = 100,
			w = 500,
			x = 60,
			valign = "top"
		})
			
		self._bg_box = HUDBGBox_create(self._panel, {
			w = 500,
			h = 38,
		})
		
		self._objective_text = self._bg_box:text({
			name = "objective_text",
			visible = false,
			layer = 2,
			color = Color.white,
			text = "",
			font_size = tweak_data.hud.active_objective_title_font_size,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
			w = self._bg_box:w(),
			x = HUDObjectives._TEXT_MARGIN
		})
		
		self._amount_text = self._bg_box:text({
			name = "amount_text",
			visible = false,
			layer = 2,
			color = Color.white,
			text = "",
			font_size = tweak_data.hud.active_objective_title_font_size,
			font = tweak_data.hud.medium_font_noshadow,
			align = "left",
			vertical = "center",
			w = self._bg_box:w(),
			x = HUDObjectives._TEXT_MARGIN
		})
	end

	function HUDObjectives:activate_objective(data)
		self._active_objective_id = data.id
		
		self._panel:set_visible(true)
		self._objective_text:set_text(utf8.to_upper(data.text))
		self._objective_text:set_visible(true)
		self._amount_text:set_visible(false)
		
		local width = self:_get_text_width(self._objective_text)
		
		if data.amount then
			self:update_amount_objective(data)
			self._amount_text:set_left(width + HUDObjectives._TEXT_MARGIN)
			width = width + self:_get_text_width(self._amount_text)
		else
			self._amount_text:set_text("")
		end

		self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + width)
		self._bg_box:stop()
		--self._amount_text:animate(callback(self, self, "_animate_new_objective"))
		--self._objective_text:animate(callback(self, self, "_animate_new_objective"))
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:update_amount_objective(data)
		if data.id ~= self._active_objective_id then
			return
		end

		self._amount_text:set_visible(true)
		self._amount_text:set_text(": " .. (data.current_amount or 0) .. "/" .. data.amount)
		self._amount_text:set_x(self:_get_text_width(self._objective_text) + HUDObjectives._TEXT_MARGIN)
		self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + self:_get_text_width(self._objective_text) + self:_get_text_width(self._amount_text))
		self._bg_box:stop()
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:remind_objective(id)
		if id ~= self._active_objective_id then
			return
		end
		
		self._bg_box:stop()
		self._bg_box:animate(callback(self, self, "_animate_update_objective"))
	end

	function HUDObjectives:complete_objective(data)
		if data.id ~= self._active_objective_id then
			return
		end

		self._amount_text:set_visible(false)
		self._objective_text:set_visible(false)
		self._panel:set_visible(false)
		self._bg_box:set_w(0)
	end

	function HUDObjectives:_animate_new_objective(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_color(Color(1, 1, 1, 1))
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_color(Color(1, 1 - (0.5 * math.sin(t * 360) + 0.5), 1, 1 - (0.5 * math.sin(t * 360) + 0.5)))
		end
		object:set_color(Color(1, 1, 1, 1))
	end

	function HUDObjectives:_animate_update_objective(object)
		local TOTAL_T = 2
		local t = TOTAL_T
		object:set_y(0)
		while t > 0 do
			local dt = coroutine.yield()
			t = t - dt
			object:set_y(math.round((1 + math.sin((TOTAL_T - t) * 450 * 2)) * (12 * (t / TOTAL_T))))
		end
		object:set_y(0)
	end

	function HUDObjectives:_get_text_width(obj)
		local _, _, w, _ = obj:text_rect()
		return w
	end	
end
	
if RequiredScript == "lib/managers/hud/hudheisttimer" then
	
	
	function HUDHeistTimer:init(hud)
		self._hud_panel = hud.panel
		if self._hud_panel:child("heist_timer_panel") then
			self._hud_panel:remove(self._hud_panel:child("heist_timer_panel"))
		end
		
		self._heist_timer_panel = self._hud_panel:panel({
			visible = true,
			name = "heist_timer_panel",
			h = 40,
			w = 50,
			valign = "top",
			layer = 0
		})
		self._timer_text = self._heist_timer_panel:text({
			name = "timer_text",
			text = "00:00",
			font_size = 28,
			font = tweak_data.hud.medium_font_noshadow,
			color = Color.white,
			align = "center",
			vertical = "center",
			layer = 1,
			wrap = false,
			word_wrap = false
		})
		self._last_time = 0
	end
end

------------------------------
-- Custom Chat Box by Seven --
------------------------------

local setup_endscreen_hud_original = HUDManager.setup_endscreen_hud

if RequiredScript == "lib/managers/hudmanagerpd2" then
 
        function HUDManager:_set_custom_hud_chat_offset(offset)
                self._hud_chat_ingame:set_offset(offset)
        end
       
        function HUDManager:setup_endscreen_hud(...)
                self._hud_chat_ingame:disconnect_mouse()
                return setup_endscreen_hud_original(self, ...)
        end
       
end
 
if RequiredScript == "lib/managers/hud/hudchat" then
       
        HUDChat.LINE_HEIGHT = 17
        HUDChat.WIDTH = 350
        HUDChat.MAX_OUTPUT_LINES = 10
        HUDChat.MAX_INPUT_LINES = 5
       
        local enter_key_callback_original = HUDChat.enter_key_callback
        local esc_key_callback_original = HUDChat.esc_key_callback
        local _on_focus_original = HUDChat._on_focus
        local _loose_focus_original = HUDChat._loose_focus
       
        function HUDChat:init(ws, hud)
                local fullscreen = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
               
                self._x_offset = (fullscreen.panel:w() - hud.panel:w()) / 2
                self._y_offset = (fullscreen.panel:h() - hud.panel:h()) / 2
                self._esc_callback = callback(self, self, "esc_key_callback")
                self._enter_callback = callback(self, self, "enter_key_callback")
                self._typing_callback = 0
                self._skip_first = false
                self._messages = {}
                self._current_line_offset = 0
                self._total_message_lines = 0
                self._current_input_lines = 1
                self._ws = ws
                self._parent = hud.panel
                self:set_channel_id(ChatManager.GAME)
               
                self._panel = self._parent:panel({
                        name = "chat_panel",
                        h = HUDChat.LINE_HEIGHT * (HUDChat.MAX_OUTPUT_LINES + 1),
                        w = HUDChat.WIDTH,
                })
               
                if HUDManager.CUSTOM_TEAMMATE_PANEL then
                        --Custom chat box position
                        self._panel:set_right(self._parent:w())
                        self._panel:set_bottom(self._parent:h())
                else
                        --Default chat box position
                        self._panel:set_left(0)
                        self._panel:set_bottom(self._parent:h() - 112)
                end
               
                self:_create_output_panel()
                self:_create_input_panel()
                self:_layout_output_panel()
        end
 
        function HUDChat:_create_input_panel()
                self._input_panel = self._panel:panel({
                        name = "input_panel",
                        alpha = 0,
                        h = HUDChat.LINE_HEIGHT,
                        w = self._panel:w(),
                        layer = 1,
                })
                local focus_indicator = self._input_panel:rect({
                        name = "focus_indicator",
                        visible = false,
                        color = Color.white:with_alpha(0.2),
                        layer = 0
                })     
                local gradient = self._input_panel:gradient({   
                        name = "input_bg",
                        visible = false,        
                        alpha = 0,      
                        gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
                        layer = -1,
                        valign = "grow",
                        blend_mode = "sub",
                })
                local bg_simple = self._input_panel:rect({
                        name = "input_bg_simple",
                        alpha = 0.5,
                        color = Color.black,
                        layer = -1,
                        h = HUDChat.MAX_INPUT_LINES * HUDChat.LINE_HEIGHT,--self._input_panel:h(),
                        w = self._input_panel:w(),
                })
               
                local input_prompt = self._input_panel:text({
                        name = "input_prompt",
                        text = utf8.to_upper(managers.localization:text("debug_chat_say")),
                        font = tweak_data.menu.pd2_small_font,
                        font_size = HUDChat.LINE_HEIGHT * 0.95,
                        h = HUDChat.LINE_HEIGHT,
                        align = "left",
                        halign = "left",
                        vertical = "center",
                        hvertical = "center",
                        blend_mode = "normal",
                        color = Color.white,
                        layer = 1
                })
                local _, _, w, h = input_prompt:text_rect()
                input_prompt:set_w(w)
                input_prompt:set_left(0)
               
                local input_text = self._input_panel:text({
                        name = "input_text",
                        text = "",
                        font = tweak_data.menu.pd2_small_font,
                        font_size = HUDChat.LINE_HEIGHT * 0.95,
                        h = HUDChat.LINE_HEIGHT,
                        w = self._input_panel:w() - input_prompt:w() - 4,
                        align = "left",
                        halign = "left",
                        vertical = "center",
                        hvertical = "center",
                        blend_mode = "normal",
                        color = Color.white,
                        layer = 1,
                        wrap = true,
                        word_wrap = false
                })
                input_text:set_right(self._input_panel:w())
               
                local caret = self._input_panel:rect({
                        name = "caret",
                        layer = 2,
                        color = Color(0.05, 1, 1, 1)
                })
               
                focus_indicator:set_shape(input_text:shape())
                self._input_panel:set_bottom(self._panel:h())
        end
 
        function HUDChat:_create_output_panel()
                local output_panel = self._panel:panel({
                        name = "output_panel",
                        h = 0,
                        w = self._panel:w(),
                        layer = 1,
                })
                local scroll_bar_bg = output_panel:rect({
                        name = "scroll_bar_bg",
                        color = Color.black,
                        layer = -1,
                        alpha = 0.35,
                        visible = false,
                        blend_mode = "normal",
                        w = 8,
                        h = HUDChat.LINE_HEIGHT * HUDChat.MAX_OUTPUT_LINES,
                })
                scroll_bar_bg:set_right(output_panel:w())
               
                local scroll_bar_up = output_panel:bitmap({
                        name = "scroll_bar_up",
                        texture = "guis/textures/pd2/scrollbar_arrows",
                        texture_rect = { 1, 1, 9, 10 },
                        w = scroll_bar_bg:w(),
                        h = scroll_bar_bg:w(),
                        visible = false,
                        blend_mode = "add",
                        color = Color.white,
                })
                scroll_bar_up:set_right(output_panel:w())
               
                local scroll_bar_down = output_panel:bitmap({
                        name = "scroll_bar_down",
                        texture = "guis/textures/pd2/scrollbar_arrows",
                        texture_rect = { 1, 1, 9, 10 },
                        w = scroll_bar_bg:w(),
                        h = scroll_bar_bg:w(),
                        visible = false,
                        blend_mode = "add",
                        color = Color.white,
                        rotation = 180,
                })
                scroll_bar_down:set_right(output_panel:w())
                scroll_bar_down:set_bottom(output_panel:h())
               
                local scroll_bar_position = output_panel:rect({
                        name = "scroll_bar_position",
                        color = Color.white,
                        alpha = 0.8,
                        visible = false,
                        blend_mode = "normal",
                        w = scroll_bar_bg:w() * 0.6,
                        h = 3,
                })
                scroll_bar_position:set_center_x(scroll_bar_bg:center_x())
               
                output_panel:gradient({
                        name = "output_bg",
                        --gradient_points = { 0, Color.white:with_alpha(0), 0.2, Color.white:with_alpha(0.25), 1, Color.white:with_alpha(0) },
                        --gradient_points = { 0, Color.white:with_alpha(0.4), 0.2, Color.white:with_alpha(0.3), 1, Color.white:with_alpha(0.2) },
                        gradient_points = { 0, Color.white:with_alpha(0.3), 0.3, Color.white:with_alpha(0.1), 0.5, Color.white:with_alpha(0.2) , 0.7, Color.white:with_alpha(0.1), 1, Color.white:with_alpha(0.3) },
                        layer = -1,
                        valign = "grow",
                        blend_mode = "sub",
                        w = output_panel:w() - scroll_bar_bg:w() ,
                })
               
                output_panel:set_bottom(self._panel:h())
        end
 
        function HUDChat:_layout_output_panel()
                local output_panel = self._panel:child("output_panel")
               
                output_panel:set_h(HUDChat.LINE_HEIGHT * math.min(HUDChat.MAX_OUTPUT_LINES, self._total_message_lines))
                if self._total_message_lines > HUDChat.MAX_OUTPUT_LINES then
                        local scroll_bar_bg = output_panel:child("scroll_bar_bg")
                        local scroll_bar_up = output_panel:child("scroll_bar_up")
                        local scroll_bar_down = output_panel:child("scroll_bar_down")
                        local scroll_bar_position = output_panel:child("scroll_bar_position")
                       
                        scroll_bar_bg:show()
                        scroll_bar_up:show()
                        scroll_bar_down:show()
                        scroll_bar_position:show()
                        scroll_bar_down:set_bottom(output_panel:h())
                       
                        local positon_height_area = scroll_bar_bg:h() - scroll_bar_up:h() - scroll_bar_down:h() - 4
                        scroll_bar_position:set_h(math.max((HUDChat.MAX_OUTPUT_LINES / self._total_message_lines) * positon_height_area, 3))
                        scroll_bar_position:set_center_y((1 - self._current_line_offset / self._total_message_lines) * positon_height_area + scroll_bar_up:h() + 2 - scroll_bar_position:h() / 2)
                end
                output_panel:set_bottom(self._input_panel:top())
 
                local y = -self._current_line_offset * HUDChat.LINE_HEIGHT
                for i = #self._messages, 1, -1 do
                        local msg = self._messages[i]
                        msg.panel:set_bottom(output_panel:h() - y)
                        y = y + msg.panel:h()
                end
        end
       
        function HUDChat:receive_message(name, message, color, icon)
                local output_panel = self._panel:child("output_panel")
                local scroll_bar_bg = output_panel:child("scroll_bar_bg")
                local x_offset = 0
               
                local msg_panel = output_panel:panel({
                        name = "msg_" .. tostring(#self._messages),
                        w = output_panel:w() - scroll_bar_bg:w(),
                })
                local msg_panel_bg = msg_panel:rect({
                        name = "bg",
                        alpha = 0.25,
                        color = color,
                        w = msg_panel:w(),
                })
 
                local heisttime = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
                local hours = math.floor(heisttime / (60*60))
                local minutes = math.floor(heisttime / 60) % 60
                local seconds = math.floor(heisttime % 60)
                local time_format_text
                if hours > 0 then
                        time_format_text = string.format("%d:%02d:%02d", hours, minutes, seconds)
                else
                        time_format_text = string.format("%d:%02d", minutes, seconds)
                end
               
                local time_text = msg_panel:text({
                        name = "time",
                        text = time_format_text,
                        font = tweak_data.menu.pd2_small_font,
                        font_size = HUDChat.LINE_HEIGHT * 0.95,
                        h = HUDChat.LINE_HEIGHT,
                        w = msg_panel:w(),
                        x = x_offset,
                        align = "left",
                        halign = "left",
                        vertical = "top",
                        hvertical = "top",
                        blend_mode = "normal",
                        wrap = true,
                        word_wrap = true,
                        color = Color.white,
                        layer = 1
                })
                local _, _, w, _ = time_text:text_rect()
                x_offset = x_offset + w + 2
               
                if icon then
                        local icon_texture, icon_texture_rect = tweak_data.hud_icons:get_icon_data(icon)
                        local icon_bitmap = msg_panel:bitmap({
                                name = "icon",
                                texture = icon_texture,
                                texture_rect = icon_texture_rect,
                                color = color,
                                h = HUDChat.LINE_HEIGHT * 0.85,
                                w = HUDChat.LINE_HEIGHT * 0.85,
                                x = x_offset,
                                layer = 1,
                        })
                        icon_bitmap:set_center_y(HUDChat.LINE_HEIGHT / 2)
                        x_offset = x_offset + icon_bitmap:w() + 1
                end
               
                local message_text = msg_panel:text({
                        name = "msg",
                        text = name .. ": " .. message,
                        font = tweak_data.menu.pd2_small_font,
                        font_size = HUDChat.LINE_HEIGHT * 0.95,
                        w = msg_panel:w() - x_offset,
                        x = x_offset,
                        align = "left",
                        halign = "left",
                        vertical = "top",
                        hvertical = "top",
                        blend_mode = "normal",
                        wrap = true,
                        word_wrap = true,
                        color = Color.white,
                        layer = 1
                })
                local no_lines = message_text:number_of_lines()
               
                message_text:set_range_color(0, utf8.len(name) + 1, color)
                message_text:set_h(HUDChat.LINE_HEIGHT * no_lines)
                message_text:set_kern(message_text:kern())
                msg_panel:set_h(HUDChat.LINE_HEIGHT * no_lines)
                msg_panel_bg:set_h(HUDChat.LINE_HEIGHT * no_lines)
               
                self._total_message_lines = self._total_message_lines + no_lines
                table.insert(self._messages, { panel = msg_panel, name = name, lines = no_lines })
               
                self:_layout_output_panel()
                if not self._focus then
                        local output_panel = self._panel:child("output_panel")
                        output_panel:stop()
                        output_panel:animate(callback(self, self, "_animate_show_component"), output_panel:alpha())
                        output_panel:animate(callback(self, self, "_animate_fade_output"))
                end
        end
 
        function HUDChat:enter_text(o, s)
                if managers.hud and managers.hud:showing_stats_screen() then
                        return
                end
                if self._skip_first then
                        self._skip_first = false
                        return
                end
                local text = self._input_panel:child("input_text")
                if type(self._typing_callback) ~= "number" then
                        self._typing_callback()
                end
                text:replace_text(s)
               
                local lbs = text:line_breaks()
                if #lbs <= HUDChat.MAX_INPUT_LINES then
                        self:_set_input_lines(#lbs)
                else
                        local s = lbs[HUDChat.MAX_INPUT_LINES + 1]
                        local e = utf8.len(text:text())
                        text:set_selection(s, e)
                        text:replace_text("")
                end
                self:update_caret()
        end
 
        function HUDChat:enter_key_callback(...)
                enter_key_callback_original(self, ...)
                self:_set_input_lines(1)
                self:_set_line_offset(0)
        end
 
        function HUDChat:esc_key_callback(...)
                esc_key_callback_original(self, ...)
                self:_set_input_lines(1)
                self:_set_line_offset(0)
        end
 
        function HUDChat:_set_input_lines(no_lines)
                if no_lines ~= self._current_input_lines then
                        no_lines = math.max(no_lines, 1)
                        self._current_input_lines = no_lines
                        self._input_panel:set_h(no_lines * HUDChat.LINE_HEIGHT)
                        self._input_panel:child("input_text"):set_h(no_lines * HUDChat.LINE_HEIGHT)
                        self._input_panel:set_bottom(self._panel:h())
                        self._panel:child("output_panel"):set_bottom(self._input_panel:top())
                end
        end
       
        function HUDChat:set_offset(offset)
                self._panel:set_bottom(self._parent:h() - offset)
        end
       
        function HUDChat:update_key_down(o, k)
                wait(0.6)
                local text = self._input_panel:child("input_text")
                while self._key_pressed == k do
                        local s, e = text:selection()
                        local n = utf8.len(text:text())
                        local d = math.abs(e - s)
                        if self._key_pressed == Idstring("backspace") then
                                if s == e and s > 0 then
                                        text:set_selection(s - 1, e)
                                end
                                text:replace_text("")
                                self:_set_input_lines(#(text:line_breaks()))
                                if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
                                end
                        elseif self._key_pressed == Idstring("delete") then
                                if s == e and s < n then
                                        text:set_selection(s, e + 1)
                                end
                                text:replace_text("")
                                self:_set_input_lines(#(text:line_breaks()))
                                if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
                                end
                        elseif self._key_pressed == Idstring("left") then
                                if s < e then
                                        text:set_selection(s, s)
                                elseif s > 0 then
                                        text:set_selection(s - 1, s - 1)
                                end
                        elseif self._key_pressed == Idstring("right") then
                                if s < e then
                                        text:set_selection(e, e)
                                elseif s < n then
                                        text:set_selection(s + 1, s + 1)
                                end
                        elseif self._key_pressed == Idstring("up") then
                                self:_change_line_offset(1)
                        elseif self._key_pressed == Idstring("down") then
                                self:_change_line_offset(-1)
                        elseif self._key_pressed == Idstring("page up") then
                                self:_change_line_offset(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines)
                        elseif self._key_pressed == Idstring("page down") then
                                self:_change_line_offset(-(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines))
                        else
                                self._key_pressed = false
                        end
                        self:update_caret()
                        wait(0.03)
                end
        end
 
        function HUDChat:key_press(o, k)
                if self._skip_first then
                        self._skip_first = false
                        return
                end
                if not self._enter_text_set then
                        self._input_panel:enter_text(callback(self, self, "enter_text"))
                        self._enter_text_set = true
                end
                local text = self._input_panel:child("input_text")
                local s, e = text:selection()
                local n = utf8.len(text:text())
                local d = math.abs(e - s)
                self._key_pressed = k
                text:stop()
                text:animate(callback(self, self, "update_key_down"), k)
                if k == Idstring("backspace") then
                        if s == e and s > 0 then
                                text:set_selection(s - 1, e)
                        end
                        text:replace_text("")
                        if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
                        end
                        self:_set_input_lines(#(text:line_breaks()))
                elseif k == Idstring("delete") then
                        if s == e and s < n then
                                text:set_selection(s, e + 1)
                        end
                        text:replace_text("")
                        if not (utf8.len(text:text()) < 1) or type(self._esc_callback) ~= "number" then
                        end
                        self:_set_input_lines(#(text:line_breaks()))
                elseif k == Idstring("left") then
                        if s < e then
                                text:set_selection(s, s)
                        elseif s > 0 then
                                text:set_selection(s - 1, s - 1)
                        end
                elseif k == Idstring("right") then
                        if s < e then
                                text:set_selection(e, e)
                        elseif s < n then
                                text:set_selection(s + 1, s + 1)
                        end
                elseif self._key_pressed == Idstring("up") then
                        self:_change_line_offset(1)
                elseif self._key_pressed == Idstring("down") then
                        self:_change_line_offset(-1)
                elseif self._key_pressed == Idstring("page up") then
                        self:_change_line_offset(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines)
                elseif self._key_pressed == Idstring("page down") then
                        self:_change_line_offset(-(HUDChat.MAX_OUTPUT_LINES - self._current_input_lines))
                elseif self._key_pressed == Idstring("end") then
                        text:set_selection(n, n)
                elseif self._key_pressed == Idstring("home") then
                        text:set_selection(0, 0)
                elseif k == Idstring("enter") then
                        if type(self._enter_callback) ~= "number" then
                                self._enter_callback()
                        end
                elseif k == Idstring("esc") and type(self._esc_callback) ~= "number" then
                        text:set_text("")
                        text:set_selection(0, 0)
                        self._esc_callback()
                end
                self:update_caret()
        end
 
        function HUDChat:_change_line_offset(diff)
                if diff ~= 0 then
                        self:_set_line_offset(math.clamp(self._current_line_offset + diff, 0, math.max(self._total_message_lines - HUDChat.MAX_OUTPUT_LINES + self._current_input_lines - 1, 0)))
                end
        end
       
        function HUDChat:_set_line_offset(offset)
                if self._current_line_offset ~= offset then
                        self._current_line_offset = offset
                        self:_layout_output_panel()
                end
        end
 
        function HUDChat:_on_focus(...)
                if not self._focus then
                        managers.mouse_pointer:use_mouse({
                                mouse_move = callback(self, self, "_mouse_move"),
                                mouse_press = callback(self, self, "_mouse_press"),
                                mouse_release = callback(self, self, "_mouse_release"),
                                mouse_click = callback(self, self, "_mouse_click"),
                                id = "ingame_chat_mouse",
                        })
                        return _on_focus_original(self, ...)
                end
        end
       
        function HUDChat:_loose_focus(...)
                self:disconnect_mouse()
                return _loose_focus_original(self, ...)
        end
       
        function HUDChat:disconnect_mouse()
                if self._focus then
                        managers.mouse_pointer:remove_mouse("ingame_chat_mouse")
                end
        end
       
        function HUDChat:_mouse_move(o, x, y)
                if self._mouse_state then
                        x = x - self._x_offset
                        y = y - self._y_offset
               
                        local output_panel = self._panel:child("output_panel")
                        self:_move_scroll_bar_position_center(y - self._panel:y() - output_panel:y())
                        self._mouse_state = y
                end
        end
       
        function HUDChat:_mouse_press(o, button, x, y)
                x = x - self._x_offset
                y = y - self._y_offset
               
                if button == Idstring("mouse wheel up") then
                        self:_change_line_offset(1)
                elseif button == Idstring("mouse wheel down") then
                        self:_change_line_offset(-1)
                elseif button == Idstring("0") then
                        local scroll_bar_position = self._panel:child("output_panel"):child("scroll_bar_position")
                        if scroll_bar_position:inside(x, y) then
                                self._mouse_state = y
                        end
                end
        end
       
        function HUDChat:_mouse_release(o, button, x, y)
                x = x - self._x_offset
                y = y - self._y_offset
               
                if button == Idstring("0") then
                        self._mouse_state = nil
                end
        end
       
        function HUDChat:_mouse_click(o, button, x, y)
                x = x - self._x_offset
                y = y - self._y_offset
               
                local output_panel = self._panel:child("output_panel")
                local scroll_bar_bg = output_panel:child("scroll_bar_bg")
                local scroll_bar_up = output_panel:child("scroll_bar_up")
                local scroll_bar_down = output_panel:child("scroll_bar_down")
                local scroll_bar_position = output_panel:child("scroll_bar_position")
               
                if scroll_bar_up:inside(x, y) then
                        self:_change_line_offset(1)
                elseif scroll_bar_down:inside(x, y) then
                        self:_change_line_offset(-1)
                elseif scroll_bar_position:inside(x, y) then
 
                elseif scroll_bar_bg:inside(x, y) then
                        self:_move_scroll_bar_position_center(y - self._panel:y() - output_panel:y())
                end
        end
       
        function HUDChat:_move_scroll_bar_position_center(y)
                local output_panel = self._panel:child("output_panel")
                local scroll_bar_bg = output_panel:child("scroll_bar_bg")
                local scroll_bar_up = output_panel:child("scroll_bar_up")
                local scroll_bar_down = output_panel:child("scroll_bar_down")
                local scroll_bar_position = output_panel:child("scroll_bar_position")
               
                y = y + scroll_bar_position:h() / 2
                local positon_height_area = scroll_bar_bg:h() - scroll_bar_up:h() - scroll_bar_down:h() - 4
                local new_line_offset = math.round((1 - ((y - scroll_bar_up:h() - 2) / positon_height_area)) * self._total_message_lines)
                self:_change_line_offset(new_line_offset - self._current_line_offset)
        end
               
end