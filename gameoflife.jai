#import "Basic";
#import "Input";
#import "Window_Creation";
#import "Simp";
#import "Math";
#import "GetRect";

#load "RLE_Loader.jai";

should_quit_game := false;

grid_size_x :: 500;
grid_size_y :: 500;

camera_zoom_min :: 0.5;
camera_zoom_max :: 5.0;

grid : [grid_size_x * grid_size_y] bool;

window_size_x := 1200;
window_size_y := 800;

global_font : Dynamic_Font;

delta_time  := 0.01667;
time_to_simulate := 0.0;
steps_per_second := 1;

is_simulating := false;
is_dragging   := false;

main :: ()
{
    #if OS == .WINDOWS
    {
        // TODO: Linux equivalent of these calls?
        #import "Windows";
        timeBeginPeriod(1);
        SetProcessDPIAware();
    }

    LoadRLEFile();

    window := create_window(window_size_x, window_size_y, "Game");
    set_render_target(window);
    ui_init();

    global_font = get_font_at_size("./", "OpenSans-BoldItalic.ttf", 32);

    grid_set_default_state();

    cell_size     := 30.0;
    line_thicness := 1.0;
    line_width    := grid_size_x * cell_size;
    line_height   := grid_size_y * cell_size;

    camera_position := make_vector2(grid_size_x * cell_size * 0.5 - window_size_x * 0.5, 
                                    grid_size_y * cell_size * 0.5 - window_size_y * 0.5);
    camera_scale_factor := 1.0;

    frame_start := current_time_monotonic();

    while !should_quit_game
    {
        update_window_events();

        x, y, success := get_mouse_pointer_position(window, true);
        mouse_position       := make_vector2(cast(float) x, cast(float) y) * camera_scale_factor;
        mouse_world_position := mouse_position + camera_position;

        aspect_ratio := cast(float) window_size_x / cast(float) window_size_y;

        mouse_index_x := cast(int) mouse_world_position.x / cast(int) cell_size;
        mouse_index_y := cast(int) mouse_world_position.y / cast(int) cell_size;

        for get_window_resizes()
        {
            update_window(window);

            if it.window != window || (window_size_x == it.width && window_size_y == it.height)
                continue;

            window_size_x = it.width;
            window_size_y = it.height;
            print("resizing window %, %\n", window_size_x, window_size_y);
        }

        for events_this_frame
        {
            if it.type == .QUIT || (it.key_pressed && it.key_code == .ESCAPE)
            {
                should_quit_game = true;
            }

            if it.key_pressed && it.key_code == #char "A"
            {
                is_simulating = false;
                simulate_generation();
            }

            if it.type == .KEYBOARD && it.key_code == .MOUSE_BUTTON_LEFT
            {
                is_dragging = it.key_pressed != 0;
            }

            if it.key_code == .MOUSE_BUTTON_RIGHT && it.key_pressed
            {
                // add cell
                if mouse_index_y < grid_size_y && mouse_index_x < grid_size_x &&
                   mouse_index_y >= 0 && mouse_index_x >= 0
                {
                    grid[mouse_index_y * grid_size_x + mouse_index_x] = !grid[mouse_index_y * grid_size_x + mouse_index_x];
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

        time_to_simulate += delta_time;

        if is_simulating && time_to_simulate > (1.0 / steps_per_second)
        {
            simulate_generation();
            time_to_simulate = 0;
        }

        if is_dragging
        {
            camera_position.x -= mouse_delta_x * camera_scale_factor * aspect_ratio;
            camera_position.y += mouse_delta_y * camera_scale_factor;
        }

        clear_render_target(.15, .08, .08, 1);

        set_shader_for_color();

        immediate_begin();
        immediate_set_2d_projection(cast(s32) (window_size_x * camera_scale_factor),
                                    cast(s32) (window_size_y * camera_scale_factor));

        my_immediate_quad(mouse_index_x * cell_size - camera_position.x,
                          mouse_index_y * cell_size - camera_position.y,
                          cell_size, cell_size, make_vector4(1) * 0.4);

        // @TODO : cull lines and cells that are not visible by the camera!
        // Draw alive cells
        for i : 0..(grid_size_x*grid_size_y)-1
        {
            if !grid[i] continue;

            offset_x := i % grid_size_x;
            offset_y := i / grid_size_x;

            my_immediate_quad(offset_x * cell_size - camera_position.x,
                              offset_y * cell_size - camera_position.y,
                              cell_size, cell_size, make_vector4(0.5, 1, 0, 1));
        }

        // Draw grid
        for y : 0..grid_size_y
        {
            xoffset : float = -camera_position.x;
            yoffset : float = y * cell_size - camera_position.y;
            my_immediate_quad(xoffset, yoffset, line_width, line_thicness * camera_scale_factor, make_vector4(0.5, 0, 0, 1));
        }

        for x : 0..grid_size_x
        {
            xoffset : float = x * cell_size - camera_position.x;
            yoffset : float = -camera_position.y;
            my_immediate_quad(xoffset, yoffset, line_thicness * camera_scale_factor, line_height, make_vector4(1, 0, 0, 1));
        }

        //immediate_quad(0.0, 0.0, xx window_size_x, xx window_size_y, Vector4.{1,1,1,1});

        immediate_flush();

        draw_and_update_ui(window);

        swap_buffers(window, false);

        frame_end := current_time_monotonic();
        delta_time = cast(float) to_float64_seconds(frame_end - frame_start);

        sleep_time := 0.01667 - delta_time;
        if(sleep_time > 0)
        {
            milliseconds := cast(s32) (sleep_time * 1000);
            sleep_milliseconds(milliseconds);
            delta_time += cast(float) to_float64_seconds(current_time_monotonic() - frame_end);
        }

        frame_start = current_time_monotonic();
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

dead_cells_per_generation    : [..] int;
spawned_cells_per_generation : [..] int;

simulate_generation :: ()
{
    for grid
    {
        if !it
            continue;

        alive_itself := it;

        x, y := get_2d_index(it_index);
        alive_neighbours := get_alive_neighbours(x, y);

        if alive_neighbours < 2 || alive_neighbours > 3
            array_add(*dead_cells_per_generation, it_index);

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

    for dead_cells_per_generation
    {
        grid[it] = false;
    }

    for spawned_cells_per_generation
    {
        grid[it] = true;
    }

    array_reset_keeping_memory(*dead_cells_per_generation);
    array_reset_keeping_memory(*spawned_cells_per_generation);
}

draw_and_update_ui :: (window: Window_Type)
{
    ui_per_frame_update(window, xx window_size_x, xx window_size_y, get_time());

    label_theme : Label_Theme;
    label_theme.font = *global_font;
    slider_theme : Slider_Theme;
    slider_theme.foreground.font = *global_font;
    slider_theme.decimals = 0;
    button_theme : Button_Theme;
    button_theme.font = *global_font;

    rect := get_rect(10, xx (window_size_y - global_font.character_height - 10), 0, xx global_font.character_height);

    gap :: 10.0;

    { // Delta time text
        draw_this : string;
        draw_this = sprint("Delta Time : %", delta_time);

        rect.w = xx prepare_text(*global_font, draw_this);
        label(rect, draw_this, *label_theme);
        rect.y -= rect.h + gap;
    }

    { // Simulation frequency slider
        rect.w = 400;
        sliding := slider(rect, *steps_per_second, 1, 60, 1, *slider_theme, "Frequency: ");
        if sliding then is_dragging = false;
        rect.y -= rect.h + gap;
    }

    { // Simulate button
        rect.w = 400;
        button_name : string;
        if is_simulating then button_name = "Stop"; else button_name = "Simulate";
        pressed, state, released := button(rect, button_name, *button_theme);

        if pressed
        {
            is_simulating = !is_simulating;
            time_to_simulate = 0;
        }

        rect.y -= rect.h + gap;
    }

    { // Reset button
        rect.w = 400;
        pressed, state, released := button(rect, "Reset to default", *button_theme);

        if pressed
        {
            for grid grid[it_index] = false;
            grid_set_default_state();
        }

        rect.y -= rect.h + gap;
    }

    { // Clear button
        rect.w = 400;
        pressed, state, released := button(rect, "Clear", *button_theme);

        if pressed
        {
            is_simulating = false;
            for grid grid[it_index] = false;
        }

        rect.y -= rect.h + gap;
    }

    t : string = "Press 'A' to step at a time";

    rect.y = 0;
    rect.w = xx prepare_text(*global_font, t);;
    rect.h = xx global_font.character_height;

    label(rect, t, *label_theme);

    draw_popups();
}

grid_set_default_state :: ()
{
    rel_x := grid_size_x / 2 - 5;
    rel_y := grid_size_y / 2;

    set :: (x : int, y : int)
    {
        if x < 0 || y < 0 || x >= grid_size_x || y >= grid_size_y { print("Failed to set default grid state\n"); return; }
        index := y * grid_size_x + x;
        grid[index] = true;
    }

    set(rel_x, rel_y);
    set(rel_x+1, rel_y-1);
    set(rel_x+2, rel_y-1);
    set(rel_x+2, rel_y+0);
    set(rel_x+2, rel_y+1);

    set(rel_x+9, rel_y-3);
    set(rel_x+10, rel_y-3);
    set(rel_x+10, rel_y-4);
    set(rel_x+11, rel_y-4);
    set(rel_x+11, rel_y-2);
}