#import "Basic";
#import "Input";
#import "Window_Creation";
#import "Simp";
#import "Math";
#import "Windows";

should_quit_game := false;

grid_size_x :: 500;
grid_size_y :: 500;

camera_zoom_min :: 0.5;
camera_zoom_max :: 5.0;

grid : [grid_size_x * grid_size_y] bool;

window_size_x :: 1200;
window_size_y :: 800;

main :: ()
{
    window := create_window(window_size_x, window_size_y, "Game");
    set_render_target(window);

    font := get_font_at_size("W:/JaiGame/", "OpenSans-BoldItalic.ttf", 40);

    cell_size     := 30.0;
    line_thicness := 1.0;
    line_width    := grid_size_x * cell_size;
    line_height   := grid_size_y * cell_size;

    camera_position     : Vector2 = make_vector2(0, 0);
    camera_scale_factor := 1.0;
    aspect_ratio        := cast(float) window_size_x / cast(float) window_size_y;

    is_dragging := false;

    while !should_quit_game
    {
        update_window_events();

        x, y, success := get_mouse_pointer_position(window, true);
        mouse_position       := make_vector2(cast(float) x, cast(float) y) * camera_scale_factor;
        mouse_world_position := mouse_position + camera_position;

        quad_index_x := cast(int) mouse_world_position.x / cast(int)cell_size;
        quad_index_y := cast(int) mouse_world_position.y / cast(int)cell_size;

        for events_this_frame
        {
            if it.type == .QUIT || (it.key_pressed && it.key_code == .ESCAPE)
            {
                should_quit_game = true;
            }

            if it.key_pressed && it.key_code == #char "A"
            {
                simulate_generation();
            }

            if it.type == .KEYBOARD && it.key_code == .MOUSE_BUTTON_LEFT
            {
                is_dragging = it.key_pressed != 0;
            }

            if it.type == .KEYBOARD && it.key_code == .MOUSE_BUTTON_RIGHT
            {
                // add cell
                if quad_index_y < grid_size_y && quad_index_x < grid_size_x &&
                   quad_index_y >= 0 && quad_index_x >= 0
                {
                    grid[quad_index_y * grid_size_x + quad_index_x] = true;
                }
            }
            
            if it.type == .MOUSE_WHEEL
            {
                scale_delta : float;

                if it.wheel_delta > 0 scale_delta = -0.1;
                else scale_delta = 0.1;

                old_scale_factor := camera_scale_factor;

                camera_scale_factor += scale_delta;
                Clamp(*camera_scale_factor, camera_zoom_min, camera_zoom_max);

                if camera_scale_factor != old_scale_factor
                {
                    delta := camera_scale_factor - old_scale_factor;
                    camera_position.x -= window_size_x * delta * 0.5;
                    camera_position.y -= window_size_y * delta * 0.5;
                }
            }
        }

        if is_dragging
        {
            camera_position.x -= mouse_delta_x * camera_scale_factor * aspect_ratio;
            camera_position.y += mouse_delta_y * camera_scale_factor;
        }

        clear_render_target(.15, .08, .08, 1);

        set_shader_for_color();
        immediate_set_2d_projection(cast(s32) (window_size_x * camera_scale_factor),
                                    cast(s32) (window_size_y * camera_scale_factor));

        immediate_begin();

        // TODD : cull lines and cells that is not visible by the camera!
        // Draw alive cells
        for i : 0..(grid_size_x*grid_size_y)-1
        {
            if !grid[i] continue;

            offset_x := i % grid_size_x;
            offset_y := i / grid_size_x;

            my_immediate_quad(offset_x * cell_size - camera_position.x,
                              offset_y * cell_size - camera_position.y,
                              cell_size, cell_size);
        }

        // Draw gird
        for y : 0..grid_size_y
        {
            xoffset : float = -camera_position.x;
            yoffset : float = y * cell_size - camera_position.y;
            my_immediate_quad(xoffset, yoffset, line_width, line_thicness * camera_scale_factor, make_vector4(1, 0, 0, 1));
        }
        
        for x : 0..grid_size_x
        {
            xoffset : float = x * cell_size - camera_position.x;
            yoffset : float = -camera_position.y;
            my_immediate_quad(xoffset, yoffset, line_thicness * camera_scale_factor, line_height, make_vector4(1, 0, 0, 1));
        }

        my_immediate_quad(quad_index_x * cell_size - camera_position.x,
                          quad_index_y * cell_size - camera_position.y,
                          cell_size, cell_size, make_vector4(0.4, 0.8, 0.4, 0.4));

        immediate_flush();

        draw_text(font, 0, window_size_y - 40, "Hello sailor!");

        swap_buffers(window);

        Sleep(1);
    }
}

my_immediate_quad :: (x : float, y : float, width : float, height : float, color := Vector4.{1,1,1,1})
{
    bot_left  := make_vector2(x, y);
    bot_right := make_vector2(x + width, y);
    top_right := make_vector2(x + width, y + height);
    top_left  := make_vector2(x, y + height);
    immediate_quad(bot_left, bot_right, top_right, top_left, color);
}

get_2d_index :: (index : int) -> x : int, y : int
{
    return index % grid_size_x, index / grid_size_x;
}

grid_is_cell_alive :: (x : int, y : int) -> bool
{
    if x < 0 || y < 0 || x >= grid_size_x || y >= grid_size_y return false;
    index := y * grid_size_x + x;
    return grid[index];
}

get_alive_neighbours :: (x : int, y : int) -> int
{
    alive_neighbours := 0;

    if grid_is_cell_alive(x-1, y)   then alive_neighbours += 1;
    if grid_is_cell_alive(x+1, y)   then alive_neighbours += 1;
    if grid_is_cell_alive(x,   y-1) then alive_neighbours += 1;
    if grid_is_cell_alive(x,   y+1) then alive_neighbours += 1;
    if grid_is_cell_alive(x-1, y-1) then alive_neighbours += 1;
    if grid_is_cell_alive(x+1, y+1) then alive_neighbours += 1;
    if grid_is_cell_alive(x+1, y-1) then alive_neighbours += 1;
    if grid_is_cell_alive(x-1, y+1) then alive_neighbours += 1;

    return alive_neighbours;
}

died_cells_per_generation    : [..] int;
spawned_cells_per_generation : [..] int;

simulate_generation :: ()
{
    for grid
    {
        alive_itself := it;
        if !alive_itself
            continue;
        
        x, y := get_2d_index(it_index);
        alive_neighbours := get_alive_neighbours(x, y);

        if alive_neighbours < 2
        {
            array_add(*died_cells_per_generation, it_index);
        }
        else if alive_neighbours > 3
        {
            array_add(*died_cells_per_generation, it_index);
        }
     
        for ox : -1..1
        {
            for oy : -1..1
            {
                nx := x + ox;
                ny := y + oy;

                if nx < 0 || ny < 0 || nx >= grid_size_x || ny >= grid_size_y
                    continue;

                if grid_is_cell_alive(nx, ny)
                    continue;
                    
                if get_alive_neighbours(nx, ny) == 3
                {
                    array_add(*spawned_cells_per_generation, ny * grid_size_x + nx);
                }    
            }
        }
    }

    for died_cells_per_generation
    {
        grid[it] = false;
    }

    for spawned_cells_per_generation
    {
        grid[it] = true;
    }

    array_reset_keeping_memory(*died_cells_per_generation);
    array_reset_keeping_memory(*spawned_cells_per_generation);
}