#import "Basic";
#import "Input";
#import "Window_Creation";
#import "Simp";
#import "Math";
#import "Windows";

should_quit_game := false;

window_size_x :: 1200;
window_size_y :: 800;

main :: ()
{
    window := create_window(window_size_x, window_size_y, "Game");
    set_render_target(window);

    font := get_font_at_size("W:/JaiGame/", "OpenSans-BoldItalic.ttf", 40);

    grid_size_x := 15;
    grid_size_y := 15;
    
    cell_size := 60.0;
    line_thicness := 1.0;
    line_width  := grid_size_x * cell_size;
    line_height := grid_size_y * cell_size;            

    camera_position : Vector2 = make_vector2(100, -100);

    is_dragging := false;
    
    while !should_quit_game
    {
        update_window_events();

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
        }

        if is_dragging
        {
            print("dragging mouse\n");

            camera_position.x -= mouse_delta_x;
            camera_position.y += mouse_delta_y;
        }
        
        //print("Mouse delta (x: %, y: %)\n", mouse_delta_x, -mouse_delta_y);
        
        clear_render_target(.15, .08, .08, 1);
        draw_text(font, 200, 200, "Hello sailor!");

        set_shader_for_color();

        immediate_begin();

        for x : 0..grid_size_x
        {
            xoffset : float = x * cell_size - camera_position.x;
            yoffset : float = -camera_position.y;
            
            bot_left  := make_vector2(xoffset, yoffset);
            bot_right := make_vector2(xoffset + line_thicness, yoffset);
            top_right := make_vector2(xoffset + line_thicness, yoffset + line_height);
            top_left  := make_vector2(xoffset, yoffset + line_height);
            immediate_quad(bot_left, bot_right, top_right, top_left);
        }
        
        for y : 0..grid_size_y
        {
            xoffset : float = -camera_position.x;
            yoffset : float = y * cell_size - camera_position.y;

            bot_left  := make_vector2(xoffset, yoffset);
            bot_right := make_vector2(xoffset + line_width, yoffset);
            top_right := make_vector2(xoffset + line_width, yoffset + line_thicness);
            top_left  := make_vector2(xoffset, yoffset + line_thicness);
            immediate_quad(bot_left, bot_right, top_right, top_left);
        }
        
        immediate_flush();

        swap_buffers(window);

        Sleep(1);
    }
}
