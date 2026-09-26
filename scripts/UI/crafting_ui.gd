extends CanvasLayer

# Set by crafting_table.gd before adding to scene tree
var world: Node = null

# ── Recipes ───────────────────────────────────────────────────────────────────
const RECIPES: Array[Dictionary] = [
	{
		"id": "iron_pickaxe",
		"name": "Iron Pickaxe",
		"icon": "res://assets/sprites/others/iron_pickaxe.png",
		"cost": {"iron": 3, "dirt": 24},
		"result_type": "pickaxe_upgrade",
		"result_value": 0.3,
		"desc_line1": "Mine blocks 40% faster.",
		"desc_line2": "Mine time: 0.3s per block"
	},
	{
		"id": "diamond_pickaxe",
		"name": "Diamond Pickaxe",
		"icon": "res://assets/sprites/others/diamond_pickaxe.png",
		"cost": {"diamond": 3, "dirt": 48},
		"result_type": "pickaxe_upgrade",
		"result_value": 0.15,
		"desc_line1": "Blazing fast mining!",
		"desc_line2": "Mine time: 0.15s per block"
	},
	{
		"id": "dynamite",
		"name": "Dynamite",
		"icon": "res://assets/sprites/others/dynamite.png",
		"cost": {"charcoal": 9, "diamond": 1},
		"result_type": "give_item",
		"result_value": "dynamite",
		"desc_line1": "Instantly destroys",
		"desc_line2": "a 3x3 area of blocks!"
	},
]

var _selected: int = 0

# ── Node refs (match new tscn paths) ─────────────────────────────────────────
@onready var recipe_btn_0: Button  = $MainPanel/Layout/BodyRow/LeftPanel/LeftContent/RecipeBtn0
@onready var recipe_btn_1: Button  = $MainPanel/Layout/BodyRow/LeftPanel/LeftContent/RecipeBtn1
@onready var recipe_btn_2: Button  = $MainPanel/Layout/BodyRow/LeftPanel/LeftContent/RecipeBtn2
@onready var icon_rect: TextureRect = $MainPanel/Layout/BodyRow/RightPanel/RightContent/TopRow/IconBG/Icon
@onready var item_name: Label      = $MainPanel/Layout/BodyRow/RightPanel/RightContent/TopRow/NameDescBox/ItemName
@onready var desc1: Label          = $MainPanel/Layout/BodyRow/RightPanel/RightContent/TopRow/NameDescBox/Desc1
@onready var desc2: Label          = $MainPanel/Layout/BodyRow/RightPanel/RightContent/TopRow/NameDescBox/Desc2
@onready var req1: Label           = $MainPanel/Layout/BodyRow/RightPanel/RightContent/Req1Row/Req1
@onready var have1: Label          = $MainPanel/Layout/BodyRow/RightPanel/RightContent/Req1Row/Have1
@onready var req2: Label           = $MainPanel/Layout/BodyRow/RightPanel/RightContent/Req2Row/Req2
@onready var have2: Label          = $MainPanel/Layout/BodyRow/RightPanel/RightContent/Req2Row/Have2
@onready var feedback_label: Label = $MainPanel/Layout/BodyRow/RightPanel/RightContent/FeedbackLabel
@onready var craft_btn: Button     = $MainPanel/Layout/BodyRow/RightPanel/RightContent/CraftBtn
@onready var close_btn: Button     = $MainPanel/Layout/TitleBar/TitleRow/CloseBtn

var _recipe_buttons: Array[Button]


func _ready() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	_recipe_buttons = [recipe_btn_0, recipe_btn_1, recipe_btn_2]

	close_btn.pressed.connect(_close)
	craft_btn.pressed.connect(_on_craft_pressed)
	recipe_btn_0.pressed.connect(func(): _select(0))
	recipe_btn_1.pressed.connect(func(): _select(1))
	recipe_btn_2.pressed.connect(func(): _select(2))

	_select(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
			_close()


# ── Recipe Selection ──────────────────────────────────────────────────────────
func _select(index: int) -> void:
	_selected = index
	var recipe: Dictionary = RECIPES[index]
	feedback_label.text = ""

	# Icon + name + description
	icon_rect.texture = load(recipe["icon"])
	item_name.text = recipe["name"]
	desc1.text = recipe["desc_line1"]
	desc2.text = recipe["desc_line2"]

	# Requirements
	var costs: Array = recipe["cost"].keys()
	var k0: String = costs[0] if costs.size() > 0 else ""
	var k1: String = costs[1] if costs.size() > 1 else ""
	var n0: int = recipe["cost"].get(k0, 0)
	var n1: int = recipe["cost"].get(k1, 0)
	var h0: int = world.inventory.get(k0, 0) if world else 0
	var h1: int = world.inventory.get(k1, 0) if world else 0

	req1.text = "• %d  %s" % [n0, k0.capitalize()]
	have1.text = "%d / %d" % [h0, n0]
	have1.modulate = Color(0.18, 0.58, 0.22, 1) if h0 >= n0 else Color(0.80, 0.15, 0.15, 1)

	if k1 != "":
		req2.text = "• %d  %s" % [n1, k1.capitalize()]
		have2.text = "%d / %d" % [h1, n1]
		have2.modulate = Color(0.18, 0.58, 0.22, 1) if h1 >= n1 else Color(0.80, 0.15, 0.15, 1)
		req2.visible = true
		have2.visible = true
	else:
		req2.text = ""
		have2.text = ""

	# Toggle button states for styling
	for i in range(_recipe_buttons.size()):
		_recipe_buttons[i].toggle_mode = true
		_recipe_buttons[i].button_pressed = (i == index)

	# Enable/disable craft button
	var can_craft: bool = _can_afford(recipe["cost"])
	craft_btn.disabled = not can_craft


# ── Crafting Logic ────────────────────────────────────────────────────────────
func _can_afford(cost: Dictionary) -> bool:
	if world == null:
		return false
	for item in cost:
		if world.inventory.get(item, 0) < cost[item]:
			return false
	return true


func _on_craft_pressed() -> void:
	var recipe: Dictionary = RECIPES[_selected]
	if not _can_afford(recipe["cost"]):
		return

	# Deduct materials
	for item in recipe["cost"]:
		world.change_inventory_item(item, -recipe["cost"][item])

	# Apply effect
	match recipe["result_type"]:
		"pickaxe_upgrade":
			var player = world.get_node_or_null("Player2")
			if player:
				player.mine_time = recipe["result_value"]
			
			# Swap the pickaxe inventory icon
			world.inventory_material["pickaxe"] = load(recipe["icon"])
			world.change_inventory_item("pickaxe", 0) # triggers UI refresh
			get_tree().call_group("inventory_ui", "update_equipped_tool", world.inventory_material["pickaxe"])
			
			feedback_label.text = "✓ %s crafted!" % recipe["name"]
			feedback_label.modulate = Color(0.18, 0.58, 0.22, 1)
		"give_item":
			world.change_inventory_item(recipe["result_value"], 1)
			feedback_label.text = "✓ %s added to inventory!" % recipe["name"]
			feedback_label.modulate = Color(0.18, 0.58, 0.22, 1)

	# Refresh UI to show updated counts
	_select(_selected)


func _close() -> void:
	get_tree().paused = false
	queue_free()
