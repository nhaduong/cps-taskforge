extends Node

func find_unique_name(parent: Node, prefix: String = '') -> String:
    var name: String
    while true:
        name = random_name(prefix)
        if not parent.has_node(name):
            break
    return name

func random_name(prefix: String) -> String:
    return prefix + str(randi())

static func get_all_children(node) -> Array:
    var nodes = []
    for N in node.get_children():

        if N.get_child_count() > 0:
    
            nodes.append(N)
    
            nodes.append_array(get_all_children(N))
    
        else:
    
            nodes.append(N)
    
    return nodes


func load_file(_file):
    var lines = []
    if FileAccess.file_exists(_file):
        var file = FileAccess.open(_file, FileAccess.READ)

        var _index = 1
        
        while not file.eof_reached(): # iterate through all lines until the end of file is reached
            var line = file.get_line()
            lines.append(line)
            _index += 1
        file.close()
    return lines


static func get_scene_loads_from_dir(path, path_contains = ''):
    var scene_loads = []

    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if dir.current_is_dir():
                print("Found directory: " + file_name)
            else:
                if file_name.get_extension() == "tscn":
                    var full_path = path.path_join(file_name)
                    scene_loads.append(load(full_path))
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path.")

    return scene_loads
