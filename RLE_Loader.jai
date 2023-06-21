LoadRLEFile :: ()
{
    file, is_read := read_entire_file("patterns/rats.rle");
    assert(is_read);

    lines := split(file, "\n");

    bound_x, bound_y : int;
    pattern_name : string;

    for lines
    {
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
                pattern_name = tprint("%", line);
            }
        }
        else if line[0] == #char "x"
        {
            // parse bound x
            line = advance(line, 4);
            line, bound_x = ParseNumber(line);

            // parse bound y
            line = advance(line, 6);
            line, bound_y = ParseNumber(line);

            // parce rule
            line = advance(line, 9);

            if(line != "B3/S23")
            {
                print("only B3/S23 rule supported!\n");
            }
        }
        else // Parse pattern
        {
            line, run_count := ParseNumber(line);

            next_tag := cast(u8) line[0];

            while !is_digit(next_tag)
            {
                if next_tag == #char "b"
                {
                }
                else if next_tag == #char "o"
                {
                }
                else if next_tag == #char "$"
                {
                }

                if line.count > 1
                {
                    line = advance(line);
                    next_tag = cast(u8) line[0];
                }
                else break;
            }

            run_count = 1;
        }
    }


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