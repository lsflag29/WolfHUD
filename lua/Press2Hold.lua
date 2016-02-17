if string.lower(RequiredScript) == "lib/units/beings/player/states/playerstandard" then

	PlayerStandard.LOCK_MODE = WolfHUD.settings.LOCK_MODE or 2														--Lock interaction, if MIN_TIMER_DURATION is longer then total interaction time, or current interaction time
	PlayerStandard.MIN_TIMER_DURATION = WolfHUD.settings.MIN_TIMER_DURATION or 5 									--Min interaction duration (in seconds) for the toggle behavior to activate
	PlayerStandard.EQUIPMENT_PRESS_INTERRUPT = WolfHUD.settings.EQUIPMENT_PRESS_INTERRUPT or not WolfHUD and true 	--Use the equipment key ('G') to toggle off active interactions
	PlayerStandard.NADE_TIMEOUT = 0.25																				--Timeout for 2 NadeKey pushes, to prevent accidents in stealth

	local _update_interaction_timers_original = PlayerStandard._update_interaction_timers
	local _check_action_interact_original = PlayerStandard._check_action_interact
	local _check_action_throw_grenade_original = PlayerStandard._check_action_throw_grenade
	
	function PlayerStandard:_update_interaction_timers(t, ...)
		self:_check_interaction_locked(t)
		return _update_interaction_timers_original(self, t, ...)
	end
	
	function PlayerStandard:_check_action_interact(t, input, ...)
		if not self:_check_interact_toggle(t, input) then
			return _check_action_interact_original(self, t, input, ...)
		end
	end
	
	
	function PlayerStandard:_check_interaction_locked(t) 
		local is_locked = false
		if PlayerStandard.LOCK_MODE == 1 then
			is_locked = self._interact_expire_t and (t - (self._interact_expire_t - self._interact_params.timer) >= PlayerStandard.MIN_TIMER_DURATION) --lock interaction, when interacting longer then given time
		elseif PlayerStandard.LOCK_MODE == 2 then
			is_locked = self._interact_params and (self._interact_params.timer > PlayerStandard.MIN_TIMER_DURATION) -- lock interaction, when total timer time is longer then given time
		end
		
		if self._interaction_locked ~= is_locked then
			managers.hud:set_interaction_bar_locked(is_locked)
			self._interaction_locked = is_locked
		end
	end
	
	function PlayerStandard:_check_interact_toggle(t, input)
		local interrupt_key_press = input.btn_interact_press
		if PlayerStandard.EQUIPMENT_PRESS_INTERRUPT then
			interrupt_key_press = input.btn_use_item_press
		end
		
		if interrupt_key_press and self:_interacting() then
			self:_interupt_action_interact()
			return true
		elseif input.btn_interact_release and self._interact_params then
			if self._interaction_locked then
				return true
			end
		end
	end
	
	function PlayerStandard:_check_action_throw_grenade(t, input, ...)
		if input.btn_throw_grenade_press then
			if managers.groupai:state():whisper_mode() and (t - (self._last_grenade_t or 0) >= PlayerStandard.NADE_TIMEOUT) then
				self._last_grenade_t = t
				return
			end
		end
		
		return _check_action_throw_grenade_original(self, t, input, ...)
	end

elseif string.lower(RequiredScript) == "lib/units/beings/player/states/playercivilian" then

	local _update_interaction_timers_original = PlayerCivilian._update_interaction_timers
	local _check_action_interact_original = PlayerCivilian._check_action_interact
	
	function PlayerCivilian:_update_interaction_timers(t, ...)
		self:_check_interaction_locked(t)
		return _update_interaction_timers_original(self, t, ...)
	end
	
	function PlayerCivilian:_check_action_interact(t, input, ...)
		if not self:_check_interact_toggle(t, input) then
			return _check_action_interact_original(self, t, input, ...)
		end
	end
	
elseif string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then

	function HUDManager:set_interaction_bar_locked(status)
		self._hud_interaction:set_locked(status)
	end
	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudinteraction" then

	HUDInteraction.SHOW_TIME_REMAINING = WolfHUD.settings.SHOW_TIME_REMAINING or true
	HUDInteraction.GRADIENT_COLOR = WolfHUD.colors[(WolfHUD.settings.GRADIENT_COLOR-1)] or Color.green

	local show_interaction_bar_original = HUDInteraction.show_interaction_bar
	local hide_interaction_bar_original = HUDInteraction.hide_interaction_bar
	local destroy_original				= HUDInteraction.destroy
	
	local set_interaction_bar_width_original = HUDInteraction.set_interaction_bar_width
	
	function HUDInteraction:set_interaction_bar_width(current, total)
		set_interaction_bar_width_original(self, current, total)
		if HUDInteraction.SHOW_TIME_REMAINING then
			self._interact_time:set_text(string.format("%.1fs", math.max(total - current, 0)))
			local perc = current/total
			local color = perc * HUDInteraction.GRADIENT_COLOR + (1-perc) * Color.white
			self._interact_time:set_color(color)
			self._interact_time:set_alpha(1)
			self._interact_time:set_visible(perc < 1)
		end
	end
	
	
	function HUDInteraction:show_interaction_bar(current, total)
		if self._interact_circle_locked then
			self._interact_circle_locked:remove()
			self._interact_circle_locked = nil
		end
		
		HUDInteraction.SHOW_TIME_REMAINING = WolfHUD.settings.SHOW_TIME_REMAINING or not WolfHUD and HUDInteraction.SHOW_TIME_REMAINING
		HUDInteraction.GRADIENT_COLOR = WolfHUD.colors[(WolfHUD.settings.GRADIENT_COLOR-1)] or HUDInteraction.GRADIENT_COLOR
		
		if PlayerStandard.LOCK_MODE < 3 and not self._interact_circle_locked then
			self._interact_circle_locked = CircleBitmapGuiObject:new(self._hud_panel, {
				radius = self._circle_radius,
				color = Color.red,
				blend_mode = "normal",
				alpha = 0,
			})
			self._interact_circle_locked:set_position(self._hud_panel:w() / 2 - self._circle_radius, self._hud_panel:h() / 2 - self._circle_radius)
			self._interact_circle_locked:set_color(Color.red)
			self._interact_circle_locked._circle:set_render_template(Idstring("Text"))
		end
		
		if HUDInteraction.SHOW_TIME_REMAINING and not self._interact_time then
			self._interact_time = self._hud_panel:text({
			name = "interaction_timer",
			visible = false,
			text = "",
			valign = "center",
			align = "center",
			layer = 1,
			color = Color.white,
			font = tweak_data.menu.default_font,
			font_size = 32,
			h = 64
			})
			
			self._interact_time:set_y(self._hud_panel:h() / 2 + 10)
			if self._interact_time then
				self._interact_time:show()
				self._interact_time:set_text(string.format("%.1fs", total))
			end
		end
		
		return show_interaction_bar_original(self, current, total)
	end
	

	function HUDInteraction:hide_interaction_bar(...)		
		if self._interact_circle_locked then
			self._interact_circle_locked:remove()
			self._interact_circle_locked = nil
		end
		
		if self._interact_time then
			self._interact_time:set_text("")
			self._interact_time:set_visible(false)
		end
		
		return hide_interaction_bar_original(self, ...)
	end

	function HUDInteraction:set_locked(status)
		if self._interact_circle_locked then
			self._interact_circle_locked._circle:set_color(status and Color.green or Color.red)
			self._interact_circle_locked._circle:set_alpha(0.25)
		end
	end
	
	function HUDInteraction:destroy()
		self._hud_panel:remove(self._interact_time)
		--self._interact_time = nil
		destroy_original(self)
	end
end