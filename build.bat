@echo off

pushd build_dir
    jai.exe -release ..\src\first.jai -msvc_format -no_cwd -output_path W:\JaiGame\build_dir\
popd