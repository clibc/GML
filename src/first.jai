#import "Basic";
#import "Input";
#import "Window_Creation";
#import "Simp";
#import "Math";
#import "Windows";

should_quit_game := false;

grid_size_x :: 50;
grid_size_y :: 50;

grid : [grid_size_x * grid_size_y] bool;

window_size_x :: 1200;
window_size_y :: 800;

my_immediate_quad :: (x : float, y : float, width : float, height : float)
{
    bot_left  := make_vector2(x, y);
    bot_right := make_vector2(x + width, y);
    top_right := make_vector2(x + width, y + height);
    top_left  := make_vector2(x, y + height);    
    immediate_quad(bot_left, bot_right, top_right, top_left);
}

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

    grid[2] = true;
    grid[3] = true;
    grid[2 + 2 * grid_size_y] = true;
    
    while !should_quit_game
    {
        update_window_events();

        x, y, success := get_mouse_pointer_position(window, true);
        mouse_position       := make_vector2(cast(float) x, cast(float) y) * camera_scale_factor;
        mouse_world_position := mouse_position + camera_position;
        
        for events_this_frame
        {
            if it.type == .QUIT || (it.key_pressed && it.key_code == .ESCAPE)
            {
                should_quit_game = true;
            }

            if it.type == .KEYBOARD && it.key_code == .MOUSE_BUTTON_LEFT
            {
                is_dragging = it.key_pressed != 0;
            }

            if it.type == .MOUSE_WHEEL
            {
                scale_delta : float;

                if it.wheel_delta > 0 scale_delta = -0.1;
                else scale_delta = 0.1;

                old_scale_factor := camera_scale_factor; 
                
                camera_scale_factor += scale_delta;
                Clamp(*camera_scale_factor, 1.0, 3.0);

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
        
        quad_index_x := cast(int) mouse_world_position.x / cast(int)cell_size;
        quad_index_y := cast(int) mouse_world_position.y / cast(int)cell_size;

        clear_render_target(.15, .08, .08, 1);
        
        set_shader_for_color();
        immediate_set_2d_projection(cast(s32) (window_size_x * camera_scale_factor),
                                    cast(s32) (window_size_y * camera_scale_factor));

        immediate_begin();

        // Draw gird
        for x : 0..grid_size_x
        {
            xoffset : float = x * cell_size - camera_position.x;
            yoffset : float = -camera_position.y;
            my_immediate_quad(xoffset, yoffset, line_thicness * camera_scale_factor, line_height);
        }

        for y : 0..grid_size_y
        {
            xoffset : float = -camera_position.x;
            yoffset : float = y * cell_size - camera_position.y;
            my_immediate_quad(xoffset, yoffset, line_width, line_thicness * camera_scale_factor);
        }

        // Draw alive cells
        for i : 0..(grid_size_x*grid_size_y)-1
        {
            if !grid[i] continue;

            offset_x := i % grid_size_x;
            offset_y := i / grid_size_y;

            my_immediate_quad(offset_x * cell_size - camera_position.x,
                              offset_y * cell_size - camera_position.y,
                             cell_size, cell_size);
        }
        
        my_immediate_quad(quad_index_x * cell_size - camera_position.x,
                          quad_index_y * cell_size - camera_position.y,
                          cell_size, cell_size);
        
        immediate_flush();

        draw_text(font, 0, window_size_y - 40, "Hello sailor!");

        swap_buffers(window);

        Sleep(1);
    }
}
