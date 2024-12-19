#!/usr/bin/awk -f

BEGIN {
    DEFAULT_COLOR = "\033[;m";
    RED           = "\033[1;31m";
    YELLOW       = "\033[1;33m";
    GREEN       = "\033[1;32m";

    # CPU_thresholds
    cpu_middle = 40; 
    cpu_high = 55; 
}

function colorize(temp, mid_trsh, high_trsh) {
    new_color = "";

    temp_number = temp;
    gsub("[^0-9]","",temp_number);
    gsub(".$","",temp_number);

    if(temp_number >= high_trsh) 
        new_color = RED;
    else if (temp_number >= mid_trsh) 
        new_color = YELLOW;
    else
        new_color = GREEN;

    return new_color temp DEFAULT_COLOR;
}

/Core/          { $3 = "\t" colorize($3, cpu_middle, cpu_high); }
/Package id/   { $4 = "\t" colorize($4, cpu_middle, cpu_high); }
# Multiple spaces added for alignment here - "\t      ".
/temp1/         { $2 = "\t      " colorize($2, cpu_middle, cpu_high) " "; }
/temp2/         { $2 = "\t      " colorize($2, cpu_middle, cpu_high) " "; }
                { print; }
