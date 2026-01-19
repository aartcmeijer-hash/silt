extends Node

func _ready():
    print("Starting SiltPhase tests...")

    # Mock GameManager and Society
    var game_manager_mock = Node.new()
    game_manager_mock.name = "GameManager"

    # We need to manually add the property since it's not in the base Node class
    game_manager_mock.set_script(load("res://scripts/GameManager.gd"))

    get_tree().root.call_deferred("add_child", game_manager_mock)
    await get_tree().process_frame

    # Verify mock setup
    if not game_manager_mock.active_society:
        game_manager_mock.active_society = SocietyResource.new()
    var society = game_manager_mock.active_society
    society.resources = {"Clay": 10, "Hides": 5}
    society.unlocked_innovations = ["Firing"]

    print("Resources set: ", society.resources)

    # Instantiate SiltPhase
    var silt_phase = load("res://scenes/silt.tscn").instantiate()
    get_tree().root.add_child(silt_phase)
    await get_tree().process_frame

    # Test spend_resources
    print("Testing spend_resources...")
    var success = silt_phase.spend_resources({"Clay": 5})
    assert(success == true, "Should be able to spend 5 Clay")
    assert(society.resources["Clay"] == 5, "Clay should be 5")
    print("spend_resources pass 1")

    success = silt_phase.spend_resources({"Hides": 10})
    assert(success == false, "Should not be able to spend 10 Hides")
    assert(society.resources["Hides"] == 5, "Hides should still be 5")
    print("spend_resources pass 2")

    # Test Innovation Requirements
    print("Testing innovation requirements...")
    var innovation_pottery = InnovationResource.new()
    innovation_pottery.name = "Pottery"
    innovation_pottery.cost = {"Clay": 1}
    innovation_pottery.requirements = ["Firing"]

    var check = silt_phase.check_innovation_requirements(innovation_pottery)
    assert(check == true, "Should meet requirements for Pottery")

    var innovation_advanced = InnovationResource.new()
    innovation_advanced.name = "Advanced Pottery"
    innovation_advanced.requirements = ["Pottery"]

    check = silt_phase.check_innovation_requirements(innovation_advanced)
    assert(check == false, "Should not meet requirements for Advanced Pottery yet")
    print("innovation requirements pass")

    # Test Purchase Innovation
    print("Testing purchase innovation...")
    success = silt_phase.purchase_innovation(innovation_pottery)
    assert(success == true, "Should be able to purchase Pottery")
    assert(society.unlocked_innovations.has("Pottery"), "Pottery should be in unlocked list")
    assert(society.resources["Clay"] == 4, "Clay should be 4")
    print("purchase innovation pass")

    # Clean up
    silt_phase.queue_free()
    game_manager_mock.queue_free()
    print("All tests passed!")
    get_tree().quit()
