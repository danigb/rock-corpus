#!/usr/bin/perl

# Takes in melodic transcription. Outputs it in various formats, and/or gathers aggregate data.
# Takes two integers on command line before file name: verbosity and rhythm-checking mode (1 = check rhythm, 0 = don't).
# verbosity:
#     If 0: Print out relative pc integers (scale degrees), absolute pcs, and (estimated) note durations, one note per line
#     If 1: Print out scale degrees, all on one line
#     If 2: Print out scale degrees, all on one line, then pitch numbers (middle C = 60), using same line breaks as input
#     If 3: Print out ontimes, pitches, and scale degrees, one note on each line (a "notelist")
#     If -1: Print out binary vector of chromatic relative scale-degrees
#     If -2: Print out proportional vector of chromatic relative scale-degree counts
#     If -3: Print out proportional vector of absolute pc counts
#     If -4: Print out proportional vector of absolute pc lengths
#     If -5: Print out time signature integers, one per line
#     If -6: Print out list of key sections
# If the file contains no notes: output just "X", except if verbosity = -3 or -4, in which case print out a uniform 1/12 vector,
# or if verbosity = -1, print out 000000000000.
#
# The basic procedure:
# First read analysis into an array of strings (separated by spaces in the input). Each string is assigned a type: 0=barline, 1=note string,
#       2 = time sig, 3 = key sig, 4 = octave marker, 5 = mode sig.
# Then go through the strings, setting time/key/mode signature where appropriate.
#       For pitch strings, replace chromatic degrees with letters - b2 = a, b3 = x, etc.
# Count the metrical units in each measure, When you get to a barline, you
#       can set the metrical position for each note.
# 
$a = @ARGV;
if($a != 3) {
    printf("Incorrect usage: should be ./process-mel5.pl [output-mode] [rhythm-checking-mode] [input-file]\n");
    exit;
}

if(!(open(INFILE, $ARGV[2]))) {
    # Comment in lines below to output an error when the file is not found. Otherwise, it will just go on.
    # printf("File '%s' not found\n", $ARGV[2]);
    printf("Error: File not found\n");
    # die;
    exit;
}

$v = $ARGV[0];
# ^ verbosity

$rhythm_checking_mode = $ARGV[1];
# 1, do it; 0, don't.

for($c=0; $c<7; $c++) {
    $modesig[$c] = 0;
}
$timesig = "4/4";
$tsint = 404;
for($x=0; $x<10000; $x++) {
    $note_line_end[$x] = $line_end[$x] = 0;
}
for($pc = 0; $pc<12; $pc++) {
    $binary[$pc] = 0;
}
$num_measures = $m = 0;
$key = -1;
$octave = -10;
# $octave = 0;
$firstnote = 1;
# The variables below are all needed for setting the metrical positions of notes and key sections
$n = $ks = $mdiv = $mfirst = $ksfirst = $last_marked_m = 0;

$w=0;

# READ INPUT

while(<INFILE>) {   

    chomp($_);
    # Erase any spaces at the beginning of the line
    $_ =~ s/^[ ]+//;

    @inwords = split(/[ ]+/, $_);

    if($inwords[0] =~ /^%/) {
	next;
    }

    $nwords = @inwords;
    for($w2=0; $w2<@inwords; $w2++) {
	if($inwords[$w2] =~ /^%/) {
	    last;
	}
	$words[$w + $w2] = $inwords[$w2];
    }
    $w += $w2;     # $w is now the index number of the first word on the NEXT line
    if($w > 0) {
	$line_end[$w-1] = 1;     # Mark the last words in each line as a "line_end". Needed if we want line breaks in output to match those in input
    }
}

$numwords = $w;

# We've read the input into an array of strings, @words. 
# print $w, "@words", "\n";

# PROCESS STRINGS

$notes_found_on_line = $notes_found_in_piece = 0;

for($w = 0; $w < $numwords; $w++) {

    $ws = $words[$w];

    if($ws eq "|") {                   # m is the number of the measure now ending      
	$type[$w] = 0;
	read_barline();
    }
    elsif($ws =~ /^\[/) {              # It's a key, mode, or time signature, or octave indicator. 
	read_special();
    }
    else {
	$type[$w] = 1;
	$notes_found_on_line = $notes_found_in_piece = 1;
	if($ws =~ /^R/) {
	    read_rest();
	}
	else {
	    read_pitch_string();
	}
    }
    if($line_end[$w]==1 && $n>0) {
	$note_line_end[$n-1] = 1;
	if($notes_found_on_line == 1 && $ws ne "|") {
	    printf("Error: Note string must be followed by barline on same line\n");
	    exit;
	}

	$notes_found_on_line = 0;
    }
}

sub read_barline {

    if($notes_found_in_piece == 0) {
	printf("Error: Can't have a barline before there have been any notes or explicit rests\n");
	exit;
    }
    #printf("(mdiv = %d) ", $mdiv);
    $mtsint[$m] = $tsint;
    set_met_positions();
    if($rhythm_checking_mode == 1 && $mdiv > 1) {
	check_rhythm();
    }
    $m++;                          # Measure number - m is now the measure starting here
    $last_marked_m = $m;           # Mark this as the last m marked with a barline
    $mdiv = 0;                     # Number of metrical divisions in the measure
    $mfirst = $n;                  # Note index number of the first note after this barline (the note has not yet been defined)
    $ksfirst = $ks;                # Keysec index number of the first keysec after this barline 
}

sub read_rest {

    if($ws ne "R") {
	if($ws !~ /^R\*[0-9]+$/) {
	    printf("Error: Invalid string: %s\n", $ws);
	    exit;
	}
	$multi_rest = $ws;
	$multi_rest =~ s/R\*//;
	for($m2=$m; $m2<$m+$multi_rest-1; $m2++) {
	    $mtsint[$m2] = $tsint;
	}
	$m += $multi_rest - 1;
    }
}

sub read_special {

    if($ws !~ /^\[.+\]$/) {
	printf("Error: Invalid string: %s\n", $ws);
	exit;
    }
    $ws =~ s/^\[//;
    $ws =~ s/\]$//;
    @chars = split(//, $ws);
    $c = @chars;
    
    if($ws =~ /OCT/) {
	$type[$w] = 4;
	if($ws !~ /^OCT=[0-9]$/) {
	    printf("Error: Invalid string: %s (octave number must be single digit, 0 through 9)\n", $ws);
	    exit;	    
	}
	if($n != 0) {
	    printf("Error: Octave declaration must be at beginning of file (before any notes or rests)\n");
	    exit;
	}
	$octave = $chars[4];
    }

    elsif($ws =~ /M=/) {
	# Comment in the next line to skip over obsolete [M=] statements
	next;
    }
    
    elsif($ws =~ /[0-9]/) {
	# It's a time signature
	$type[$w] = 2;
	for($w2=$w-1; $w2>=0; $w2--) {
	    if($line_end[$w2] == 1) {
		last;
	    }
	    if($type[$w2] == 0) {
		last;
	    }
	    if($type[$w2] == 1) {
		printf("Error: Time signature must be at beginning of measure\n");
		exit;
	    }
	}
	if($ws !~ /^[0-9]+\/[0-9]+$/ && $ws ne "0") {
	    printf("Error: Invalid string: %s\n", $ws);
	    exit;	    
	}
	$timesig = $ws;
	if($timesig eq "0") {
	    $tsint = 0;
	}
	else {
	    # Create integer out of time signature, e.g. 4/4 = 404
	    @tsbits = split(/\//, $timesig);
	    $tsnum = $tsbits[0];
	    $tsdenom = $tsbits[1];
	    $tsint = ($tsnum * 100) + $tsdenom;
	}
    }
    
    elsif($ws =~ /[A-G]/) {
	# It's a key symbol
	$type[$w] = 3;
	# reset mode sig to Ionian
	for($c=0; $c<7; $c++) {
	    $modesig[$c] = 0;
	}
	if($ws eq "C") {
	    $key = 0;
	}
	elsif($ws eq "Db" || $ws eq "C#") {
	    $key = 1;
	}
	elsif($ws eq "D") {
	    $key = 2;
	}
	elsif($ws eq "Eb" || $ws eq "D#") {
	    $key = 3;
	}
	elsif($ws eq "E") {
	    $key = 4;
	}
	elsif($ws eq "F") {
	    $key = 5;
	}
	elsif($ws eq "F#" || $ws eq "Gb") {
	    $key = 6;
	}
	elsif($ws eq "G") {
	    $key = 7;
	}
	elsif($ws eq "Ab" || $ws eq "G#") {
	    $key = 8;
	}
	elsif($ws eq "A") {
	    $key = 9;
	}
	elsif($ws eq "Bb" || $ws eq "A#") {
	    $key = 10;
	}
	elsif($ws eq "B") {
	    $key = 11;
	}
	else {
	    printf("Error: Invalid string: %s\n", $ws);
	    exit;	    
	}
	$keysec_key[$ks] = $key;
	$kmdiv[$ks] = $mdiv;
	$ks++;
    }
    
    elsif($ws =~ /\./) {
	if($ws !~ /^.......$/ || $ws !~ /^[\.b]+$/) {
	    printf("Error: Invalid string: %s\n", $ws);
	    exit;	    
	}
	# It's a mode signature
	$type[$w] = 5;
	for($c=0; $c<7; $c++) {
	    if($chars[$c] eq 'b') {
		$modesig[$c] = -1;
	    }
	    elsif($chars[$c] eq '.') {
		$modesig[$c] = 0;
	    }
	}
    }
    else {
	printf("Error: Invalid string: %s\n", $ws);
	exit;	    
    }

}

sub read_pitch_string {

    if($ws !~ /^[1234567\.b#n_\-\=v\^]+$/) {
	printf("Error: Invalid string: %s\n", $ws);
	exit;
    }

    @chars = split(//, $ws);
    $nc = @chars;
    for($c=0; $c<$nc-1; $c++) {
	if($chars[$c] =~ /[b#n]/) {
	    if($chars[$c+1] !~ /[1-7]/) {
		printf("Error: Invalid string: %s\n", $ws);
	    }
	}
	elsif($chars[$c] =~ /[\^v]/) {
	    if($chars[$c+1] !~ /[1234567b#n\^v]/) {
		printf("Error: Invalid string: %s\n", $ws);
	    }
	}
    }

    if($firstnote == 1) {
	$firstnote = 0;
	if($octave == -10) {
	    printf("Error: Octave must be specified before first note\n");
	    exit;
	}
	if($key == -1) {
	    printf("Error: key must be specified before first note\n");
	    exit;
	}
    }

    # Replace "_" with "...." or "..."

    $ws =~ s/_/..../g;
    $ws =~ s/\=/....../g;
    $ws =~ s/\-/.../g;

    # $ws will represent scale-degrees, with one character per note (possibly with preceding v/^): 
    # natural scale-degrees = 1-7; #1/b2 = a, #2/b3 = x, #4/b5 = c, #5/b6 = d, #6/b7 = e.
    
    # Replace altered scale-degrees with single characters a/x/c/d/e
    
    $ws =~ s/#1|b2/a/g;
    $ws =~ s/#2|b3/x/g;
    $ws =~ s/#4|b5/c/g;
    $ws =~ s/#5|b6/d/g;
    $ws =~ s/#6|b7/e/g;
    
    # Replace "altered-to-diatonic" degrees with diatonic numbers 
    
    $ws =~ s/b1/n7/g;
    $ws =~ s/b4/n3/g;
    $ws =~ s/#3/n4/g;
    $ws =~ s/#7/n1/g;
    
    # If the string contains n, leave as is. 
    
    # Alter notes according to mode signature: 2 -> a, 3 -> x, 5 -> c, 6 -> d, 7 -> e, but only if they'r NOT preceded by n.
    
    if($modesig[1]==-1) {
	$ws =~ s/(?<!n)2/a/g;
    }
    if($modesig[2]==-1) {
	$ws =~ s/(?<!n)3/x/g;
    }
    if($modesig[4]==-1) {
	$ws =~ s/(?<!n)4/c/g;
    }
    if($modesig[5]==-1) {
	$ws =~ s/(?<!n)6/d/g;
    }
    if($modesig[6]==-1) {
	$ws =~ s/(?<!n)7/e/g;
    }
    
    #printf("%s\n", $ws);
    
    # Now get rid of all n's.
    
    if($ws =~ /n/) {
	$ws =~ s/n//g;
    }

    @chars = split(//, $ws);

    $pos = 0;
    $shift = 0;

    # Now the pitch string is just one character per note, except for v and ^. Go through it, setting the chromatic scale-degree
    # (@chrom) and pitch (@pitch) of each note.

    for($c=0; $c < @chars; $c++) {

	if($chars[$c] eq ".") {
	    $mdiv++;
	    next;
	}
	
	if($chars[$c] eq "v") {
	    $shift -= 1;
	    next;
	}
	if($chars[$c] eq "^") {
	    $shift += 1;
	    next;
	}
	
	$chrom[$n] = sd($chars[$c]);

	$nm[$n] = $m;      # The measure number of note n (currently not used)
	$nmdiv[$n] = $mdiv;  # The metrical division number of note n
	
	$pc = ($chrom[$n] + $key) % 12;
	if($n==0) {
	    $pitch[0] = $pc + (12 * ($octave + 1));
	    #printf("First note\n");
	}
	else {
	    $pitch[$n] = closest($pc, $previous);
	    #printf("Here with n2 = %d, chrom[n2] = %d, shift = %d, prev = %d, pitch = %d\n", $n, $chrom[$n], $shift, $previous, $pitch[$n]);
	}
	$previous = $pitch[$n];
	
	#printf("%d:%d ", $chrom[$n], $pitch[$n]);
	
	$shift = 0;
	
	$mdiv++;
	$prev_ws = $ws;
	$n++;
    }    

}

sub sd {

    if($_[0] == 1) {
	0;
    }
    elsif($_[0] eq 'a') {
	1;
    }
    elsif($_[0] == 2) {
	2;
    }
    elsif($_[0] eq 'x') {
	3;
    }
    elsif($_[0] == 3) {
	4;
    }
    elsif($_[0] == 4) {
	5;
    }
    elsif($_[0] eq 'c') {
	6;
    }
    elsif($_[0] == 5) {
	7;
    }
    elsif($_[0] eq 'd') {
	8;
    }
    elsif($_[0] == 6) {
	9;
    }
    elsif($_[0] eq 'e') {
	10;
    }
    elsif($_[0] == 7) {
	11;
    }

}

sub closest {

    $current_pc = $_[0];
    $prev_pitch = $_[1];
    $prev_pc = $prev_pitch % 12;
    # diff = signed clock difference
    $diff = (($current_pc - $prev_pc) + 12) % 12;

    $new_pitch = $prev_pitch + $diff;

    #printf("prev = %d, diff = %d, new = %d\n", $prev_pitch, $diff, $new_pitch);

    if($diff > 6) {
	$new_pitch -= 12;
    }

    $new_pitch += ($shift * 12);

}

sub set_met_positions {

    for($n2=$mfirst; $n2<$n; $n2++) {
	$notetime[$n2] = $m + ($nmdiv[$n2] / $mdiv);
	#printf("%.3f (%d,%d)\n", $notetime[$n2], $chrom[$n2], $pitch[$n2]);
    }
    for($ks2=$ksfirst; $ks2<$ks; $ks2++) {
	if($mdiv == 0) {
	    $div = 1;
	}
	else {
	    $div = $mdiv;
	}
	$keysec_time[$ks2] = $last_marked_m + ($kmdiv[$ks2] / $div);
	#printf("%.3f (%d, lmm=%d)\n", $keysec_time[$ks2], $keysec_key[$ks2], $last_marked_m);
    }

}

sub check_rhythm {

    if($timesig eq "4/4") {
	if(!($mdiv == 2 || $mdiv == 4 || $mdiv == 8 || $mdiv == 16 || $mdiv == 32)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "2/4") {
	if(!($mdiv == 2 || $mdiv == 4 || $mdiv == 8 || $mdiv == 16)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "3/4") {
	if(!($mdiv == 3 || $mdiv == 6 || $mdiv == 12 || $mdiv == 24)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "12/8") {
	if(!($mdiv == 2 || $mdiv == 4 || $mdiv == 12 || $mdiv == 24 || $mdiv == 48)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "9/8") {
	if(!($mdiv == 3 || $mdiv == 9 || $mdiv == 18 || $mdiv == 36)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "6/8") {
	if(!($mdiv == 2 || $mdiv == 6 || $mdiv == 12 || $mdiv == 24)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "7/8") {
	if(!($mdiv == 7 || $mdiv == 14 || $mdiv == 28)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig eq "5/4") {
	if(!($mdiv == 5 || $mdiv == 10 || $mdiv == 20 || $mdiv == 40)) {
	    printf("Error: %s\n", $prev_ws);
	    exit();
	}
    }
    elsif($timesig ne "0") {
	printf("Error: Time signature '%s' not recognized\n", $timesig);
	exit();
    }
}


# GET AGGREGATE STATS

$num_measures = $m;
$num_keysecs = $ks;
$numnotes = $total_length = 0;

for($pc=0; $pc<12; $pc++) {
    $count[$pc] = $abspc[$pc] = $sdlength[$pc] = $abslength[$pc] = 0;
}

# Create $binary[] vector, in which a pc's value is 1 if it ever occurs; also a $count[] vector, with raw SD counts, and an $abspc[] 
# vector that counts abs pc's; also an $sdlength[] vector and a $abslength[] vector, counting total length, assuming length = 
# min($max_length, IOI)

$max_length = 1.0;
for($n=0; $n<@chrom; $n++) {
    $binary[$chrom[$n]]=1;
    $count[$chrom[$n]]++;
    $abspc[ $pitch[$n] % 12 ]++;
    if($n < @chrom-1) {
	if($notetime[$n+1] <= $notetime[$n] + $max_length) {
	    $noteend[$n] = $notetime[$n+1];
	}
	else {
	    $noteend[$n] = $notetime[$n] + $max_length;
	}
    }
    else {
	$noteend[$n] = $notetime[$n] + $max_length;
    }
    $sdlength[$chrom[$n]] += ($noteend[$n] - $notetime[$n]);
    $abslength[$pitch[$n] % 12] += ($noteend[$n] - $notetime[$n]);
    $total_length += ($noteend[$n] - $notetime[$n]);
    $numnotes++;
}

# OUTPUT

if($v == 0) {
    for($n=0; $n<@chrom; $n++) {
	printf("%d %d %.3f\n", $chrom[$n], $pitch[$n] % 12, $noteend[$n] - $notetime[$n]);
    }
}

if($v == 1 || $v == 2) {
    # Print out pitch numbers, all on one line
    for($n=0; $n<@chrom; $n++) {
	printf("%d ", $chrom[$n]);
    }
    printf("\n");
}

if($v == 2) {
    # Print out scale-degree numbers, following line breaks in input
    printf("\n");
    for($n=0; $n<@pitch; $n++) {
	printf("%d ", $pitch[$n]);
	if($note_line_end[$n] == 1) {
	    printf("\n");
	}
    }
    printf("\n");
}

if($v == 3 && $numnotes > 0) {

    # Print out ontimes and pitches (like a note list, but without offtimes)
    for($n=0; $n<@pitch; $n++) {
	printf("%5.3f %d %d\n", $notetime[$n], $pitch[$n], $chrom[$n]);
    }
}

if($v == -1) {
    # Print binary SD vector
    if($numnotes == 0) {
	printf("000000000000\n");
    }
    else {
	for($pc=0; $pc<12; $pc++) {
	    printf("%d", $binary[$pc]);
	}
	printf("\n");
    }
}

if($v == -2) {
    # Print SD distribution
    if($numnotes == 0) {
	printf("X\n");
    }
    else {
	for($pc=0; $pc<12; $pc++) {
	    printf("%0.3f ", $count[$pc] / $numnotes);
	}
	printf("\n");
    }
}

if($v == -3 || $v == -4) {
    # Print absolute PC vector, weighted by duration (-4) or not (-3)
    if($numnotes == 0) {
	#    printf("X\n");
	for($pc=0; $pc<12; $pc++) {
	    printf("%0.3f ", 1 / 12.0);
	}   
	printf("\n");
    }
    else {
	for($pc=0; $pc<12; $pc++) {
	    if($v == -3) {
		printf("%0.3f ", $abspc[$pc] / $numnotes);
	    }
	    else {
		printf("%0.3f ", $abslength[$pc] / $total_length);
	    }
	}
	printf("\n");
    }
}

if($v == -5) {
    # Print list of measures with a time sig for each
    for($m=0; $m<$num_measures; $m++) {
	printf("%d %d\n", $m, $mtsint[$m]);
    }
}

if($v == -6) {
    # Print list of key sections with a key for each
    for($ks=0; $ks<$num_keysecs; $ks++) {
	if($ks < $num_keysecs - 1) {
	    if($keysec_time[$ks] == $keysec_time[$ks+1]) {
		next;
	    }
	}
	printf("%.3f %d\n", $keysec_time[$ks], $keysec_key[$ks]);
    }
}
