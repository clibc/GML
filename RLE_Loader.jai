RLETagType :: enum_flags u8
{
    DEAD;
    ALIVE;
    ENDLINE;
}

RLEPattern :: struct
{
    name    : string;
    bound_x : int;
    bound_y : int;
    tags    : [..] RLETagType;
}

LoadRLEFile :: (file_path : string) -> RLEPattern
{
    file, is_read := read_entire_file(file_path);
    assert(is_read);

    lines := split(file, "\n");

    pattern          : RLEPattern;

    encountered_bang := false;

    for lines
    {
        if encountered_bang
            break;

        line := it;
        if line[line.count - 1] == #char "\r"
            line.count -= 1;

        line = eat_spaces(line);

        if line[0] == #char "#"
        {
            identifier := line[1];
            if(identifier == #char "N")
            {
                line = advance(line, 2);
                line = eat_spaces(line);
                pattern.name = tprint("%", line);
            }
        }
        else if line[0] == #char "x"
        {
            // parse bound x
            line = advance(line, 4);
            line, pattern.bound_x = ParseNumber(line);

            // parse bound y
            line = advance(line, 6);
            line, pattern.bound_y = ParseNumber(line);

            // parce rule
            line = advance(line, 9);

            if(line != "B3/S23" && line != "b3/s23")
            {
                print("only B3/S23 rule supported!\n");
            }
        }
        else // Parse pattern
        {
            local_line := line;
            while local_line.count > 0
            {
                character := cast(u8) local_line[0];

                run_count := 0;
                tag : RLETagType = 0;

                if is_digit(character)
                {
                    local_line, run_count = ParseNumber(local_line);
                    character = cast(u8) local_line[0];
                }

                if character == #char "b"
                {
                    tag = RLETagType.DEAD;
                }
                else if character == #char "o"
                {
                    tag = RLETagType.ALIVE;
                }
                else if character == #char "$"
                {
                    tag = RLETagType.ENDLINE;
                }

                if tag != 0
                {
                    run_count = ifx run_count > 0 then run_count else 1;

                    for 1..run_count
                    {
                        array_add(*pattern.tags, tag);
                    }
                }

                if character == #char "!"
                {
                    encountered_bang = true;
                    break;
                }

                local_line.data  += 1;
                local_line.count -= 1;
            }
        }
    }

    return pattern;
}

#scope_file

// @NOTE: This only parses positive integers!
ParseNumber :: (str_arg : string) -> string, int
{
    value  := 0;

    str := str_arg;
    next := cast(u8) str[0];

    if !is_digit(next) return str_arg, -1;

    place := 1_000_000_000_000_000_000;
    while true
    {
        digit : int = next - #char "0";
        value += digit * place;

        if str.count > 1
        {
            str = advance(str);
            next = cast(u8) str[0];
            if !is_digit(next) break;

            place /= 10;
        }
        else break;
    }

    if place == 0
    {
        // overflowed decimal places!!
        print("Unable to parse number: number is too big%\n", str_arg);
        return str_arg, -1;
    }

    value /= place;

    return str, value;
}

#import "Math";
#import "File";
#import "String";
