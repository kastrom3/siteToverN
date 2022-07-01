class Game_Event
  alias_method :setup_page_settings_noitemdisappear, :setup_page_settings
  def setup_page_settings
    setup_page_settings_noitemdisappear
    @move_route = nil if event.name[0..4]=='Item'
  end
end

module Battle_System
  alias_method :take_skill_effect_nofriendlyfire, :take_skill_effect
  def take_skill_effect(user,skill,can_sap=false,force_hit=false)
    #Companion is hit by player
    if $game_player.actor == user &&
      self.master == $game_player
        return map_token.perform_dodge 
    end
    take_skill_effect_nofriendlyfire(user,skill,can_sap,force_hit)
  end
end

class Game_Actor
  alias_method :take_skill_effect_nofriendlyfire, :take_skill_effect
  def take_skill_effect(user,skill,can_sap=false,force_hit=false)
    #Companion hits player
    if self == $game_player.actor &&
      user.master == $game_player 
        return map_token.perform_dodge
    end
    take_skill_effect_nofriendlyfire(user,skill,can_sap,force_hit)
  end
end

class CheatUtils
  def self.heal_player
    $game_player.actor.health += 999
    $game_player.actor.sta += 999
    $game_player.actor.sat += 999
  end

end

class Scene_Base

  @autoheal = false

	alias_method :trigger_debug_window_entry_CHEAT, :trigger_debug_window_entry
	def trigger_debug_window_entry
		trigger_debug_window_entry_CHEAT
	if Input.trigger?(Input::F11)
		@autoheal = !@autoheal
		SndLib.sys_ok
    end
	if Input.trigger?(Input::F9)
		SceneManager.call(Scene_Debug)
	end
    if Input.trigger?(Input::F8)
		$game_player.actor.learn_skill(63) #DebugPrintChar
		$game_player.actor.learn_skill(58) #BasicDance
		SndLib.sys_ok
	end
    if Input.trigger?(Input::F7)
	    $story_stats["WorldDifficulty"] += 3
		SndLib.sys_ok
	end
    if Input.trigger?(Input::F6)
	    $story_stats["WorldDifficulty"] -= 3
		SndLib.sys_ok
	end
    if Input.trigger?(Input::F5)
		$game_player.actor.level = 99
		$game_player.actor.trait_point += 99
		SndLib.sys_ok
    end
    if @autoheal
		CheatUtils.heal_player
    end
	end

  def return_scene
    SceneManager.return
  end
end

module SceneManager
  def self.call(scene_class)
    @stack.push(@scene)
    @scene = scene_class.new
  end

  def self.return
    @scene = @stack.pop
  end
end

#==============================================================================
# ¦ Window_DebugSwitch
#==============================================================================

class Window_DebugSummon < Window_Command

  #--------------------------------------------------------------------------
  # initialize
  #-------------------------------------------------------------------------
  def initialize
    begin
      @prefix = ''
      compute_folders
    rescue => e
      p "Oops, something gone wrong: cannot summon event because #{e.message}"
    end
    super(160, 0)
    deactivate
    hide
    refresh
  
  end

  def compute_folders
    @folders = []
    $data_monster_lib.each_key do |key|
      begin
        camel_split = key.split(/(?=[A-Z])/).reject {|x| x.empty? }
        unless camel_split.empty?
          @folders.push(camel_split[0])
        end
      rescue => e
        p "Oops, something gone wrong: cannot compute folders because #{e.message}"
      end
    end
    @folders.uniq!
    @folders.sort!
  end
  
  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width; return Graphics.width - 160; end
  
  #--------------------------------------------------------------------------
  # window_height
  #--------------------------------------------------------------------------
  def window_height; return Graphics.height - 120; end
  
  #--------------------------------------------------------------------------
  # make_command_list
  #--------------------------------------------------------------------------
  def make_command_list
    unless @prefix.empty?
      add_command('Back', :subfolder, true, '')
      $data_monster_lib.each_key{|key|
        name = key
        camel_split = name.split(/(?=[A-Z])/).reject {|x| x.empty? }
        if camel_split[0] == @prefix
          text = camel_split.join('')
          add_command(text, :summon, true, key)
        end
      }
    else
      @folders.each{|folder|
        add_command(folder, :subfolder, true, folder)
      }
    end
  rescue => e
    p "Oops, something gone wrong: cannot because #{e.message}"
	end
  
  def subfolder
    name = current_ext
    begin
      if name.nil?
        name = ''
      end
      @prefix = name
      clear_command_list
      make_command_list
      refresh
      select(0)
      activate
      SndLib.sys_ok
    rescue => e
      p "Oops, something gone wrong: cannot summon event #{name} because #{e.message}"
      SndLib.sys_buzzer
    end
  end

	def summonCurrent
    name = current_ext
    if @prefix.empty? || name == 'Back' || name.empty?
      return subfolder
    end
		
		begin
			if !name.nil? then
				$game_map.summon_event(name, $game_player.x, $game_player.y)
				SndLib.sys_ok
			end
		rescue => e
			p "Oops, something gone wrong: cannot summon event #{name} because #{e.message}"
			SndLib.sys_buzzer
		end
	end

	def cursor_left(wrap = false)
		cursor_pageup
	end
	def cursor_right(wrap = false)
		cursor_pagedown
	end
end # Window_DebugSummon

##---------------------------------------------------------------------------
## ¦ Pregnancy Menu
##---------------------------------------------------------------------------
class Window_DebugPreg < Window_Command
  
  #--------------------------------------------------------------------------
  # initialize
  #-------------------------------------------------------------------------
  def initialize
    super(160, 0)
    deactivate
    hide
    refresh
  end
  
  #--------------------------------------------------------------------------
  # window_width
  #--------------------------------------------------------------------------
  def window_width; return Graphics.width - 160; end
  
  #--------------------------------------------------------------------------
  # window_height
  #--------------------------------------------------------------------------
  def window_height; return Graphics.height - 120; end
  
  #--------------------------------------------------------------------------
  # make_command_list
  #--------------------------------------------------------------------------
    def make_command_list
        add_command("Human",        :pregCurrent,  true, "Human")
        add_command("Deepone",      :pregCurrent,  true, "Deepone")
        add_command("Fishkind",     :pregCurrent,  true, "Fishkind")
        add_command("Orkind",       :pregCurrent,  true, "Orkind")
        add_command("Goblin",       :pregCurrent,  true, "Goblin")
        add_command("Abomination",  :pregCurrent,  true, "Abomination")
        
    end
    
    def pregCurrent
		name = current_ext
		begin
			if !name.nil? then
				$game_player.actor.set_preg(name, days = 0)
				SndLib.sys_ok
			end
		rescue => e
			p "Oops, something gone wrong: cannot do event #{name} because #{e.message}"
			SndLib.sys_buzzer
		end
	end
    
	def cursor_left(wrap = false)
		cursor_pageup
	end
	def cursor_right(wrap = false)
		cursor_pagedown
	end
end # Window_DebugSummon

    
module YEA
module DEBUG
    COMMANDS =[
        [ :summon,  "Summon"],
        [ :make_pregnant,  "Impregnate"],
        [ :heal, "Heal"],
        [ :healw, "Heal Wounds"],
        [ :gib, "Give Money"],
        [ :stronk, "Give Trait Points"],
        [ :moot, "Make me Moot"],
        [ :human, "Make me Human"],
        [ :predeepone, "Make me DeepOne"],
        [ :deepone, "Make me True DeepOne"],
        [ :fall, "Exhausted"],
        [ :good, "Make me Morally Good"],
        [ :evil, "Make me more evil"],
        [ :pregplus, "Make me more Pregnant"]

        
	]
end
end

class Scene_Debug < Scene_MenuBase
	def create_command_window
		@command_window = Window_DebugCommand.new
		@command_window.set_handler(:cancel, method(:return_scene))
		@command_window.set_handler(:summon, method(:command_summon))
        @command_window.set_handler(:make_pregnant, method(:command_pregnant))
        @command_window.set_handler(:heal, method(:command_heal))
        @command_window.set_handler(:healwound, method(:command_healwound))
        @command_window.set_handler(:gib, method(:command_gib_moneh))
        @command_window.set_handler(:stronk, method(:command_make_stronk))
        @command_window.set_handler(:moot, method(:command_make_moot))
        @command_window.set_handler(:human, method(:command_make_human))
        @command_window.set_handler(:predeepone, method(:command_make_predeepone))
        @command_window.set_handler(:deepone, method(:command_make_deepone))
        @command_window.set_handler(:fall, method(:command_exhaust))
        @command_window.set_handler(:good, method(:command_make_good))
        @command_window.set_handler(:evil, method(:command_make_evil))
        @command_window.set_handler(:pregplus, method(:command_preg_plus))
	end

    # Summon Window
	def create_summon_window
		@summon_window = Window_DebugSummon.new
		@summon_window.set_handler(:ok, method(:on_summon_ok))
		@summon_window.set_handler(:cancel, method(:on_summon_cancel))
	end

	def on_summon_ok
		@summon_window.activate
		@summon_window.summonCurrent
	end
	def on_summon_cancel
		@dummy_window.show
		@summon_window.hide
		@command_window.activate
		refresh_help_window
	end


	def command_summon
		create_summon_window if @summon_window == nil
		@dummy_window.hide
		@summon_window.show
		@summon_window.activate
		refresh_help_window
	end # Summon window
    
    # Pregnancy Window
    def create_preg_window
		@preg_window = Window_DebugPreg.new
        @preg_window.set_handler(:ok, method(:on_preg_ok))
		@preg_window.set_handler(:cancel, method(:on_preg_cancel))
	end
    
	def on_preg_ok
		@preg_window.activate
        @preg_window.pregCurrent
	end
	def on_preg_cancel
		@dummy_window.show
		@preg_window.hide
		@command_window.activate
		refresh_help_window
	end
    def command_pregnant
        create_preg_window if @preg_window == nil
		@dummy_window.hide
		@preg_window.show
		@preg_window.activate
		refresh_help_window
    end # Pregnancy Window
    
    
    def command_heal
		$game_player.actor.health += 999
        $game_player.actor.sta += 999
        $game_player.actor.sat += 999
		@command_window.activate
		refresh_help_window
	end
    
    
    def command_healwound
		$game_player.actor.heal_wound
        @command_window.activate
		SndLib.sys_ok
		refresh_help_window
	end
    
    def command_gib_moneh
		$game_party.gain_gold += 300
		@command_window.activate
		refresh_help_window
	end
    
    def command_make_stronk
        $game_player.actor.trait_point += 1
        @command_window.activate
		refresh_help_window
    end
    
    def command_make_moot
        $game_player.actor.race = "Moot"
        $game_player.actor.stat["Race"] = "Moot"
        $game_player.actor.record_lona_race = "Moot"
        $game_player.actor.add_state(52)
        $game_player.actor.erase_state(50)
        $game_player.actor.erase_state(53)
        @command_window.activate
		refresh_help_window
    end
    
    def command_make_human
        $game_player.actor.record_lona_race = "Human"
        $game_player.actor.stat["Race"] = "Human"
        $game_player.actor.race = "Human"
        
        $game_player.actor.erase_state(50)
        $game_player.actor.erase_state(52)
        $game_player.actor.erase_state(53)
        @command_window.activate
		refresh_help_window
    end
    
    def command_make_predeepone
        $game_player.actor.record_lona_race = "PreDeepone"
        $game_player.actor.stat["Race"] = "Human"
        $game_player.actor.race = "Human"
        
        $game_player.actor.add_state(53)
        $game_player.actor.erase_state(50)
        $game_player.actor.erase_state(52)
        @command_window.activate
		refresh_help_window
    end
    
    def command_make_deepone
        $game_player.actor.record_lona_race = "TrueDeepone"
        $game_player.actor.stat["Race"] = "Deepone"
        $game_player.actor.race = "Deepone"
        
        $game_player.actor.add_state(50)
        $game_player.actor.erase_state(52)
        $game_player.actor.erase_state(53)
        
        @command_window.activate
		refresh_help_window
    end
    
    def command_exhaust
        $game_player.actor.sta = -100
        @command_window.activate
		refresh_help_window
        
    end
    
    def command_make_good
        $game_player.actor.morality_lona = 100
        @command_window.activate
		refresh_help_window
    end
    
    def command_make_evil
        $game_player.actor.morality_lona = $game_player.actor.morality_lona - 10
        @command_window.activate
		refresh_help_window
    end
    
    def command_preg_plus
        if ($game_player.actor.preg_level >= 1) then 
            if ($game_player.actor.preg_level < 5) then
                $game_player.actor.preg_level += 1
            end
            if ($game_player.actor.preg_level = 5) then
               $game_actors[1].lactation_level += 100 
            end
        end
        @command_window.activate
		refresh_help_window
    end
            
	def refresh_help_window
		if @command_window.active
			text  = ""
		else
			case @command_window.current_symbol
			when :summon
				text  = "Select NPC to summon.\n"
				text += "Press Z to summon.\n"
				text += "\n"
				text += ""
            when :make_pregnant
				text  = "Select race.\n"
				text += "Press Z to select.\n"
				text += "\n"
				text += ""
			else
				text  = ""
			end
		end
		@help_window.contents.clear
		@help_window.draw_text_ex(4, 0, text)
	end
end