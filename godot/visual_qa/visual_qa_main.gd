extends Control

const ProductionMain := preload("res://scenes/main/Main.tscn")
const VisualQaBootstrap := preload("res://visual_qa/visual_qa_bootstrap.gd")

func _ready() -> void:
  var main_screen := ProductionMain.instantiate()
  main_screen.name = "ProductionMain"
  add_child(main_screen)
  var bootstrap := VisualQaBootstrap.new()
  bootstrap.name = "VisualQaBootstrap"
  bootstrap.main_screen = main_screen
  add_child(bootstrap)
