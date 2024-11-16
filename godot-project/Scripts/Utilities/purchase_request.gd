# A request made to upgrade or downgrade a tower stat
class_name PurchaseRequest

var is_upgrade: bool
# purchase cost
var amount: int
var stat_type: String
var tower_name: String
# networking id of purchaser
var purchaser_id 
var purchaser_username

var tower_type
var cell

func _init(_is_upgrade,_amount,_stat_type,_tower_name,_purchaser_id,_purchaser_username,_tower_type=-1,_cell=Vector2(-1,-1)):
    self.is_upgrade = _is_upgrade
    self.amount = _amount
    self.stat_type = _stat_type
    self.tower_name = _tower_name
    self.purchaser_id = _purchaser_id
    self.purchaser_username = _purchaser_username

    self.tower_type = _tower_type
    self.cell = _cell
