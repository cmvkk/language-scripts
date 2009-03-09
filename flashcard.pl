#!/usr/bin/env perl

# Takes a tab-separated list with a variable number of columns and some header information
# and creates flashcards for it.  Automatically generates a list of options.
# 
# Written by William D. Lipe (cmvkk) in 2005
# This code is hereby released into the public domain, no rights reserved.

use warnings;
use strict;

use CGI;

sub FCL_PATH () { "/homeb/wlipe/public_html/cgi-bin" } #path to FCL files
sub CSS_LOC () { "http://people.ku.edu/~wlipe/vocab.css" } #URL for CSS file

sub prelim {
	my $cgi = new CGI;
	my %params = $cgi->Vars;
	
	print $cgi->header(-charset=>'utf8'); #Might as well put this where CGI is already instantiated

	if (!%params) {

		&renderFiles;

	} elsif (!$params{file}) {
		
		my $file = $params{keywords};
		
		if ($file !~ /.*\.fcl$/) {
			$file = $file . ".fcl";
		}
		renderCP($file);		

	} elsif (!$params{mode}) {

		renderCP($params{file});	

	} elsif ($params{mode} eq 'flash') {

		renderFlash(\%params);

	} elsif ($params{mode} eq 'list') {

		renderList(\%params);

	} else {

		print "Sorry, invalid options selected.\n" and die;

	}
}

sub makeList {
    #opens the list file and produces the list and its info from it
	my ($file) = @_;

	chdir(FCL_PATH);
	open(my $fhandl, '<', $file)
		or die("Cannot open file ${file}: $!");

	my $title = <$fhandl>;
	
	my @list = (); #this is an array of array refs, one per item,
	               #the refs containing each column's data for that item

	while (<$fhandl>) {
		chomp;
		my @line = split(/\t/, $_);
		push (@list, \@line);
	}
	close $fhandl;

	my $head1 = shift(@list); #column names
	my $head2 = shift(@list); #column types ('C' or 'D')
	
	
	my %classes = (); #hash containing, for each C column, the index and an
	                  #array ref holding the possible values of that column.

	for (my $i = 0; $i < scalar(@$head1); $i++) {
		if ($$head2[$i] eq 'C') {
			my @things = []; #list of current column's possible values

			foreach my $item (@list) { #pick out the value of the column if it 
				my $curitem = $$item[$i];     #hasn't already been picked out.

				SENT: {
					foreach my $gotitem (@things) {
						last SENT if $curitem eq $gotitem; 
					}
					push(@things, $curitem);
				}
			}
			$classes{$i} = \@things;
		}
	}

	return ($title, $head1, $head2, \%classes, \@list);
}

sub getFmtList {
    #takes the list, it's info, and the params and crops, hides, and sorts the list accordingly
	my ($head1, $head2, $classes, $list, $params) = @_;

	for (my $i = 0; $i < scalar(@$head2); $i++) { #cuts out the non-included lines
		if ($$head2[$i] eq 'C') {                         #$i is a C-column

			for (my $j = 0; $j < scalar(@$list); $j++) { #$j is a list item

				my $curCvalue = 'inc' . $i . '-' . htmlClean($$list[$j][$i]);

				unless (exists $$params{$curCvalue}) { 
					delete $$list[$j];
				}
			}
		}
	}

	my @newlist = ();
	for (my $i = 0; $i < scalar(@$list); $i++) { #fricken removes those empty list items!
		push(@newlist, $$list[$i]) unless !$$list[$i];
	}

	for (my $i = 0; $i < scalar(@$head2); $i++) { #shows or hides the D elements
		if ($$head2[$i] eq 'D') {
			
			if (exists $$params{"hid" . $i}) {
				for (my $j = 0; $j < scalar(@newlist); $j++) {
					$newlist[$j][$i] = "<p class=\"hide\">" . $newlist[$j][$i] . "</p>";
				}
			} else {
				for (my $j = 0; $j < scalar(@newlist); $j++) {
					$newlist[$j][$i] = "<p class=\"show\">" . $newlist[$j][$i] . "</p>";
				}
			}
	
		}
	}
	

	if ($$params{mode} eq 'flash') {
		$list = randomizeList(\@newlist);
	} else {
		$list = sortList(\@newlist, $head1, $params);
	}

	return $list;
}


sub sortList {	
	#sorts list based on $params
	my ($list, $head, $params) = @_;
	my $curnum = 0;
	
	for (my $i = (scalar(@$head) - 1); $i >= 0; $i--) { #counts backwards across the number
	                                                    #of possible sorts that need to be done.
	
		my $curparam = "sort" . $i;          #contains the current parameter to sort with
		
		my $curnum = 0;
		for (my $j = 0; $j < scalar(@$head); $j++) { 
			$curnum = $j if ($$head[$j] eq $$params{$curparam}); #the index of the current column to sort for
		}
		
		unless ($$params{$curparam} eq "No Preference") {
			@$list = sort {$$a[$curnum] cmp $$b[$curnum]} @$list;
		}
		
	}
	
	return $list;
}


sub randomizeList {
	#randomly switches the items of the list around!!!1
	my ($list) = @_;

	for (my $i = 0; $i < scalar(@$list); $i++) {
		my $rand = int(rand(scalar(@$list) - $i));
		$rand += $i;
		my $temp = $$list[$i];
		$$list[$i] = $$list[$rand];
		$$list[$rand] = $temp;
	}

	return $list;

}


sub htmlClean {
	#used to clean the column-names for options in the HTML form
	my ($string) = @_;
	
	$string =~ s/&/&amp\;/g; 
	$string =~ s/</&lt\;/g;
	$string =~ s/>/&gt\;/g;
	$string =~ s/"/&quot;/g;
	$string =~ s/'/&#39;/g;
	$string =~ s/,/&#44;/g;

	return $string;
	
}

sub renderCP {
	my ($file) = @_;
	
	my ($title, $head1, $head2, $classes, $list) = makeList($file);
	drawCP($title, $file, drawCPStuff($classes, $head1, $head2));

}

sub drawCP {
my ($title, $file, $include, $hide, $sort) = @_;

print q{
<html>
<head>
<link href="} . CSS_LOC . q{" rel="stylesheet" type="text/css" />
<title>Controls - }.$title.q{</title>
</head>
<body>
<form method="post" action="flashcard.pl">
<center><table>
  <tr>
    <td><h1>}.$title.q{</h1></td>
  </tr>
  <tr>
    <td>
      <input type="radio" name="mode" value="list">List 
      <input type="radio" name="mode" value="flash" checked>Flash
    </td>
  </tr>
  <tr>
    <td>
	  <h2>Include</h2>
	  } . $include . q{


    </td>
  </tr>
  <tr>
    <td>
	  <h2>Hide</h2>
	  } . $hide . q{


    </td>
  </tr>
  <tr>
    <td>
	  <h2>Sort</h2>
	  } . $sort . q{
	  
	  <input type="checkbox" name="hed" value="y">Use Headers<br>
	</td>
  </tr>
  <tr>
    <td>
	  <input type="hidden" name="file" value="} . $file . q{">
	  <input type="Submit" name="Submit" value="Submit">
	</td>
  </tr>



</table></center>
</form>
</body>
</html>
};

}


sub drawCPStuff {
	my ($classes, $head1, $head2) = @_;
	
	my $incl = '';
	
	while (my ($num, $items) = each %$classes) {
		$incl .= "<strong>" . ${$head1}[$num] . "</strong><br>";
		shift(@{$items});

		foreach (@{$items}) {
			$incl .= q{ <input type="checkbox" name="inc} . $num . "-" . htmlClean($_) .
			         q{" value="y">} . $_ . "<br>\n";
		}
		$incl .= "\n";
	}
	
	my $hide = '';
	
	for (my $i = 0; $i < scalar(@$head1); $i++) {
		if ($$head2[$i] eq 'D') {
			$hide .= q{ <input type="checkbox" name="hid} . $i . qq{" value="y">} . $$head1[$i];
		}
	}
	
	my $sort = '';
	
	for (my $i = 0; $i < scalar(@$head1); $i++) {
		if ($i == 0) {
			$sort .= "Sort by: ";
		} else {
			$sort .= "then by: ";
		}
		
		$sort .= q{<select name="sort} . $i . qq{">\n<option>No Preference</option>\n};
		
		foreach (@$head1) {
			$sort .= "<option>" . htmlClean($_) . "</option>\n";
		}
		$sort .= qq{</select><br>\n};
	}
			

	return ($incl, $hide, $sort);
}



sub renderFlash {
	my ($params) = @_;
	my $file = $$params{file};
	
	my ($title, $head1, $head2, $classes, $list) = makeList($file);
	my ($newlist) = getFmtList($head1, $head2, $classes, $list, $params);
	
	my ($body) = drawFlashStuff($newlist, $head2);
	drawFlash($title, $body);


}

sub drawFlash {
my ($title, $body) = @_;

print q{
<html>
<head>
<link href="} . CSS_LOC . q{" rel="stylesheet" type="text/css" />
<title>Flashcard - }.$title.q{</title>
</head>
<body><center>
<div id="flash">

} . $body . q{

</div>
</body>
</html>

};

}

sub drawFlashStuff {
	my ($list, $head2) = @_;
	my $out = '';
	
	my $itr = 0;
	foreach (@$list) {
		unless (!$_) {
			$out .= q{<a name="}.$itr.qq{"><div class="smspacer"></div>\n<table class="card">};
			for (my $i = 0; $i < scalar(@$head2); $i++) {
				if ($$head2[$i] eq 'D') {
					$out .= q{<tr><td align="center">}.$$_[$i].q{</tr>};
				}
			}
			$itr++;
			$out .= qq{</table>\n<br><a href="#}.$itr.q{">next</a><div class="spacer"></div>};
		}
	}	

	return ($out);

}

sub renderList {
	my ($params) = @_;
	my $file = $$params{file};
	
	my ($title, $head1, $head2, $classes, $list) = makeList($file);
	my ($newlist) = getFmtList($head1, $head2, $classes, $list, $params);
	
	my ($body) = drawListStuff($newlist, $head1, $head2, $params);
	drawList($title, $body);

}

sub drawList {
	my ($title, $body) = @_;
	
print q{

<html>
<head>
<link href="} . CSS_LOC . q{" rel="stylesheet" type="text/css" />
<title>List - }.$title.q{</title>
</head>
<body>
<h1>List - }.$title.q{</h1><p>
<div id="list">
<table border=0>

} . $body . q{

</table>
</div>
</body>
</html>

};

}

sub drawListStuff {
	my ($list, $head1, $head2, $params) = @_;
	my $out = '';
	
	my $curnum = undef;
	
	if ($$params{hed}) {
		for (my $j = 0; $j < scalar(@$head1); $j++) { 
			$curnum = $j if ($$head1[$j] eq $$params{sort0}); #the index of the current column to sort for
		}
	}
		
	
	my $curhed = '';
	
	foreach (@$list) {
		if (defined($curnum)) { #using headers
			if ($$_[$curnum] ne $curhed) { #we need a new header
				$curhed = $$_[$curnum];
				$out .= "<tr><td><h3>" . $curhed . "</h3></td></tr>";
			}
		}
	
		$out .= "<tr>";
		for (my $i = 0; $i < scalar(@$head2); $i++) {
			if ($$head2[$i] eq 'D') {
				$out .= "<td>" . $$_[$i] . "</td>\n";
			}
		}
		$out .= "</tr>";
	}
	
	return $out;

}

sub renderFiles {
	chdir(FCL_PATH);
	my @files = glob("*.fcl");
	
	my $body = drawFilesStuff(@files);
	drawFiles($body);

}

sub drawFiles {
	my ($body) = @_;
	
print q{

<html>
<head>
<link href="} . CSS_LOC . q{" rel="stylesheet" type="text/css" />
<title>List of Available Files</title>
</head>
<body>
<h1>Please Choose a File</h1><br>
<table>

} . $body . q{

</body>
</html>

};

}

sub drawFilesStuff {
	my @files = @_;
	my $out = '';
	
	if (!@files) {
		$out .= "<tr><td>No Files Available.</td></tr>";
	} else {
		foreach (@files) {
			$out .= q{<tr><td><a href="flashcard.pl?file=}.$_.q{">}.$_.q{</a></td></tr>};
		}
	}
	
	return $out;
}

&prelim; #OKAY GO

