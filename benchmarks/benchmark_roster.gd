extends SceneTree

func _init():
    print("Running benchmark...")

    var survivor_script = load("res://resources/SurvivorResource.gd")

    # Configuration
    # We use a large size to exaggerate the difference
    var ROSTER_SIZE = 10000
    var REMOVAL_PERCENTAGE = 0.5 # 50% to remove

    print("Roster Size: ", ROSTER_SIZE)
    print("Removal Percentage: ", REMOVAL_PERCENTAGE * 100, "%")

    # --- Benchmark Original ---
    var roster_original: Array[Resource] = []
    for i in range(ROSTER_SIZE):
        var s = survivor_script.new()
        if i < ROSTER_SIZE * REMOVAL_PERCENTAGE:
            s.age_decades = 5 # Will become 6 and removed
        else:
            s.age_decades = 0
        roster_original.append(s)

    # Shuffle to ensure removal is scattered (erase search impact)
    roster_original.shuffle()

    var time_start = Time.get_ticks_msec()

    # Original Logic
    var survivors_to_remove = []
    for survivor in roster_original:
        survivor.age_decades += 1
        if survivor.age_decades > 5:
            survivors_to_remove.append(survivor)

    for s in survivors_to_remove:
        roster_original.erase(s)

    var time_end = Time.get_ticks_msec()
    print("Original Time: ", time_end - time_start, "ms")

    # --- Benchmark Optimized ---
    var roster_optimized: Array[Resource] = []
    for i in range(ROSTER_SIZE):
        var s = survivor_script.new()
        if i < ROSTER_SIZE * REMOVAL_PERCENTAGE:
            s.age_decades = 5
        else:
            s.age_decades = 0
        roster_optimized.append(s)

    roster_optimized.shuffle()

    time_start = Time.get_ticks_msec()

    # Optimized Logic (Backward iteration)
    for i in range(roster_optimized.size() - 1, -1, -1):
        var survivor = roster_optimized[i]
        survivor.age_decades += 1
        if survivor.age_decades > 5:
            roster_optimized.remove_at(i)

    time_end = Time.get_ticks_msec()
    print("Optimized Time: ", time_end - time_start, "ms")

    quit()
