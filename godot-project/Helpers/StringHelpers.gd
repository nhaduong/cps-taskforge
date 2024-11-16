extends Node
class_name StringHelpers


static func string_to_vector2(string := "") -> Vector2:
    if string:
        var new_string: String = string
        new_string.erase(0, 1)
        new_string.erase(new_string.length() - 1, 1)
        var array: Array = new_string.split(",")
        print_debug(array[0],array[1])
        return Vector2(float(array[0]), float(array[1]))

    return Vector2.ZERO
