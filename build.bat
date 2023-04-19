@echo off

pushd build_dir
    jai.exe ..\src\first.jai -msvc_format -no_cwd -exe first.jai -output_path W:\JaiGame\build_dir\
popd