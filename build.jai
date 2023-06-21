#import "Compiler";

#run build();

build :: ()
{
    w := compiler_create_workspace();
    options := get_build_options();
    options.output_executable_name = "gameoflife";
    options.output_path = "./";
    options.intermediate_path = "./intermediate_files/";
    options.use_visual_studio_message_format = true;
    options.use_natvis_compatible_types = true;

    set_build_options(*options, w);

    add_build_file("./gameoflife.jai", w);
    set_build_options_dc(.{do_output=false});
}
