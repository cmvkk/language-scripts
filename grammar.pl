#!/usr/bin/env perl

# This code produces a frontend for an SQL database
# intended to be used to document grammatical constructs...
# State of operation unknown
#
# Written by William D. Lipe (cmvkk) in 2005
# This code is hereby released into the public domain, no rights reserved.


use warnings;
use strict;

use CGI::Carp qw(fatalsToBrowser);

use CGI;
use DBI;

#constants
#sub whatever () { value }
sub disable_posting () { 1 } 	#0 - all posting enabled
								#1 - all posting disabled
								#2 - index posting disabled
sub items_per_page () { 20 }
sub comments_per_page () { 5 }

sub page_title () { "Korean Grammar Index" }
sub page_description () { "Fill in later." }
sub first_language () { "Korean" }
sub second_language () { "English" }

sub db_location () { "DBI:mysql:blah" }
sub db_server () { "localhost" }
sub db_user () { "root" }
sub db_password () { "sh1bb2l3th4" }



sub renderIndex { # $items (array ref of hash refs), $start (int)
	#renders the HTML for the index page
	my ($items, $start, $srchstr) = @_;

	my ($nav, $thispage) = makeNav('index', $start, $srchstr, scalar(@$items));

	#first the top stuff
	print "<html><head>\n<link href=\"grammar.css\" rel=\"stylesheet\" ";
	print "type=\"text/css\" />\n";
	print "<title>" . page_title . "</title></head>\n";
	print "<body>\n";
	print "<div id=\"header\"><div class=\"hfbody\">\n";
	print "<h1>" . page_title . "</h1>\n";
	print "<h2>" . page_description . "</h2>\n";
	print "<p class=\"search\">Search the database:<br>\n";
	print "<FORM method=\"get\" action=\"grammar.pl\">\n";
	print "<input type=\"hidden\" name=\"item\" value=\"search\">\n";
	print "<input type=\"text\" name=\"srchstr\" size=40><input type=\"submit";
	print "\" value=\"Search\"></form></p></div>\n";
	print "<p class=\"nav\">" . $nav . "</p>\n";
	print "<span class=\"b c t l tl\"></span>\n";
	print "<span class=\"b c t r tr\"></span>\n";
	print "<span class=\"b x top\"></span>\n";
	print "<span class=\"b y r right\"></span>\n";
	print "<span class=\"b y l left\"></span></div>\n";
	print "<div id=\"main\">\n";

	#render the table with all the results on it
	if (!@$items) {
		print "<div class=\"even\"><center>\n";
		print "<p class=\"comment\">Your search returned no results.</p>\n";
		print "</div>\n";
	} else {
		print "<table>\n";
		for (my $i = $start; $i < ($start + $thispage); $i++) {
			if (($i % 2) == 0) {
				print "<tr class=\"even\">\n";
			} else {
				print "<tr class=\"odd\">\n";
			}
	
			my $linkurl = "grammar.pl?item=" . @$items[$i]->{id};
	
			print " <td class=\"num\"><a href=\"" . $linkurl . "\">";
			print $$items[$i]->{id} . "</a></td>\n";
			print " <td><a href=\"" . $linkurl . "\">";
			print $$items[$i]->{kordef} . "</a></td>\n";
			print " <td><a href=\"" . $linkurl . "\">";
			print $$items[$i]->{engdef} . "</a></td>\n";
			print "</tr>\n";
		}
		print "</table>\n";
	}

	#footer stuff
	print "</table>\n";
	print "<span class=\"b y r right\"></span>\n";
	print "<span class=\"b y l left\"></span>\n";
	print "</div>\n";
	print "<div id=\"footer\">";
	print "<p class=\"nav\">" . $nav . "</p>\n";
	print "<div class=\"hfbody\">\n";
	print "<form method=\"post\" action=\"grammar.pl\">\n";
	print "<input type=hidden name=method value=idx>\n";
	print "Add a new entry:<br>\n";
	print first_language . ": <input type=text size=80 maxlength=254 name=def1><br>\n";
	print second_language . ": <input type=text size=80 maxlength=254 name=def2><br>\n";
	print "Character: <input type=text size=3 maxlength=1 name=alch><br>\n";
	print "<input type=submit value=send>";
	print "</form></div>\n";
	print "<span class=\"b c b l bl\"></span>\n";
	print "<span class=\"b c b r br\"></span>\n";
	print "<span class=\"b y r right\"></span>\n";
	print "<span class=\"b y l left\"></span>\n";
	print "<span class=\"b x bottom\"></span>\n";
	print "</div></body></html>\n";


}

sub renderComment { # $itemdef (hash ref), $comments (array ref of hash refs)
	#renders the HTML for the comment page
	my ($itemdef, $comments, $start) = @_;

	my ($nav, $thispage) = makeNav('comments', $start, $itemdef->{id}, scalar(@$comments));

	print "<html><head>\n";
	print "<link href=\"grammar.css\" rel=\"stylesheet\" type=\"text/css\" />\n";
	print "<title>" . page_title . "</title>\n";
	print "</head><body>\n";
	print "<div id=\"header\"><div class=\"hfbody\">\n";
	print "<h1>" . page_title . "</h1>\n";
	print "<h2>" . page_description . "</h2>";
	print "<p class=\"search\">Search the index:<br>\n";
	print "<FORM method=\"get\" action=\"grammar.pl\">\n";
	print "<input type=\"hidden\" name=\"item\" value=\"search\">\n";
	print "<input type=\"text\" name=\"srchstr\" size=40><input type=\"submit";
	print "\" value=\"Search\"></form></p>\n";
	print "<p>Item " . $itemdef->{id} . "</p>\n";
	print "<p>" . first_language . " Def: " . $itemdef->{kordef} . "</p>\n";
	print "<p>" . second_language . " Def: " . $itemdef->{engdef} . "</p>\n";
	print "</div><p class=\"nav\">" . $nav . "</p>\n";
	print "<span class=\"b c t l tl\"></span>\n";
	print "<span class=\"b c t r tr\"></span>\n";
	print "<span class=\"b x top\"></span>\n";
	print "<span class=\"b y r right\"></span>\n";
	print "<span class=\"b y l left\"></span>\n";
	print "</div><div id=\"cmain\">\n";

	if (!@$comments) {
		print "<div class=\"even\"><center>\n";
		print "<p class=\"comment\">This item has no comments.</p>\n";
		print "</div>\n";
	} else {
		for (my $i = $start; $i < ($start + $thispage); $i++) {
			if (($i % 2) == 0) {
				print "<div class=\"even\">\n";
			} else {
				print "<div class=\"odd\">\n";
			}
			print "<p class=\"chead\">";
			print $$comments[$i]->{ordid} . " - " . $$comments[$i]->{timestamp};
			print "</p>\n";
			print "<p class=\"comment\">\n";
			print $$comments[$i]->{body};
			print "</p></div>\n";
		}
	}

	print "<span class=\"b y r right\"></span>\n";
	print "<span class=\"b y l left\"></span>\n";
	print "</div><div id=\"footer\">\n";
	print "<p class=\"nav\">" . $nav . "</p><div class=\"hfbody\">\n";
	print "<FORM METHOD=POST ACTION=\"grammar.pl\"><br>\n";
	print "<input type=hidden name=method value=itm>\n";
	print "<input type=hidden name=itm value=" . $itemdef->{id} . ">\n";
	print "Add a New Comment: <br><textarea rows=\"8\" cols=\"80\" name=\"body\">";
	print "</textarea><br>\n";
	print "<input type=submit value=send></form></div>\n";
	print "<span class=\"b c b l bl\"></span>\n";
	print "<span class=\"b c b r br\"></span>\n";
	print "<span class=\"b y r right\"></span>\n";
	print "<span class=\"b y l left\"></span>\n";
	print "<span class=\"b x bottom\"></span>\n";
	print "</div>\n";
	print "</body></html>\n";
}

sub getIndex { # $srchstr, $start (not used here)
	#SQL query for index, should contain the search stuff
	my ($srchstr, $start) = @_;

	my $dbh = DBI->connect(db_location, db_user, db_password,
		{ RaiseError => 1, AutoCommit => 0 });

	my $items; #will contain hash refs for result rows

	if (!$srchstr) { #no searching necessary :)
		my $sth = $dbh->prepare("SELECT * FROM items");
		$sth->execute;

		$items = $sth->fetchall_arrayref({});

	} else { #the search code!
		my @srchterms = termSplit($srchstr);

		my ($one, $two, $three); #mysql strings for each search
		$one = "SELECT * FROM items ";
		$two = "UNION SELECT * FROM items ";
		$three = "UNION SELECT * FROM items WHERE id IN (SELECT refid FROM comments ";

		$one = $one . "WHERE engdef LIKE ? ";
		$two = $two . "WHERE kordef LIKE ? ";
		$three = $three . "WHERE body LIKE ? ";

		for (my $i = 1; $i < @srchterms; $i++) {
			$one = $one . "AND engdef LIKE ? ";
			$two = $two . "AND kordef LIKE ? ";
			$three = $three . "AND body LIKE ? ";
		}

		my $sqlquery = $one . $two . $three . ")";
		
		my $sth = $dbh->prepare($sqlquery);
		$sth->execute(@srchterms, @srchterms, @srchterms);

		$items = $sth->fetchall_arrayref({});

	} 

	$dbh->disconnect;

	renderIndex($items, $start, $srchstr);

}

sub getComment { # $item, $start (not used here)
	#SQL query for comment
	my ($item, $start) = @_;

	my $dbh = DBI->connect(db_location, db_user, db_password,
		{ RaiseError => 1, AutoCommit => 0 });

	my $sth = $dbh->prepare("SELECT * FROM items WHERE id = ?");
	$sth->execute($item);

	my $itemdef = $sth->fetchrow_hashref;

	$sth = $dbh->prepare("SELECT * FROM comments WHERE refid = ?");
	$sth->execute($item);

	my $comments = $sth->fetchall_arrayref({});

	$dbh->disconnect;

	renderComment($itemdef, $comments, $start);

}

sub postIndex { # $engdef, $kordef, $alch
	#SQL adding the new index entry.  Should call getIndex afterwards
	my ($def1, $def2, $alch) = @_;

	formatIndex($def1);
	formatIndex($def2);
	formatIndex($alch);

	my $dbh = DBI->connect(db_location, db_user, db_password,
		{ RaiseError => 1, AutoCommit => 0 });
	
	my $sth = $dbh->prepare("INSERT INTO items VALUES ('', '', ?, ?, ?)");
	$sth->execute($def1, $def2, $alch);

	$dbh->disconnect;

	getIndex();

}

sub postComment { # $itm, $body
	#SQL adding the new comment entry. Should call getComment afterwards
	my ($item, $body) = @_;

	$body = formatComment($body);

	my $dbh = DBI->connect(db_location, db_user, db_password,
		{ RaiseError => 1, AutoCommit => 0 });

	my $sth = $dbh->prepare("SELECT ordid FROM comments WHERE refid = ?");
	$sth->execute($item);

	my $ord = $sth->rows;
	$ord++;

	my $timestamp;
	my @times = localtime;
	$times[5] += 1900;
	$timestamp = $times[5] . "-" . $times[4] . "-" . $times[3];
	$timestamp = $timestamp . " " . $times[2] . ":" . $times[1] . ":" . $times[0]; 

	$sth = $dbh->prepare("INSERT INTO comments VALUES (?, ?, ?, ?)");
	$sth->execute($item, $ord, $timestamp, $body);

	$dbh->disconnect;

	getComment($item);

}

sub formatIndex { # $engdef, $kordef, $alch

	foreach my $buff (@_) { #just strips the HTML
		s/&/&amp\;/g; 
		s/</&lt\;/g;
		s/>/&gt\;/g;
	}

}

sub formatComment { # $body

	$_ = shift;

	# < and > to &lt; and &gt;, \n to <br>
	s/&/&amp\;/g; 
	s/</&lt\;/g;
	s/>/&gt\;/g;
	s/\n/<br>\n/g;

	# surrounding * ~ _ and % chars with <strong>, <em>, etc
	s/(?<!\\)\*(.*?)(?<!\\)\*/<strong>$1<\/strong>/gs;
	s/(?<!\\)~(.*?)(?<!\\)~/<em>$1<\/em>/gs;
	s/(?<!\\)_(.*?)(?<!\\)_/<u>$1<\/u>/gs;
	s/(?<!\\)%(.*?)(?<!\\)%/<span style=\"color: red\">$1<\/span>/gs;

	# fixes escaped chars
	s/\\\*/*/g;
	s/\\~/~/g;
	s/\\_/_/g;
	s/\\%/%/g;

	# [url] type links -> HTML
	s/(?<!\\)\[(\d+?)(?<!\\)\]/<a href=\"grammar.pl?item=$1\">$1<\/a>/g;
	s/(?<!\\)\[(.+?)(?<!\\)\|(\d+?)(?<!\\)\]/<a href=\"grammar.pl?item=$2\">$1<\/a>/g;
	s/(?<!\\)\[([^\|]+?)(?<!\\)\]/<a href=\"$1\">$1<\/a>/g;
	s/(?<!\\)\[(.+?)(?<!\\)\|(.+?)(?<!\\)\]/<a href=\"$2\">$1<\/a>/g;

	# more escape fixing
    s/\\\[/[/g;
    s/\\\]/]/g;
    s/\\\|/|/g;

	return $_;

}

sub termSplit { #$srchstr
	my ($srchstr) = @_;

	my @buff = split(/ *" */, $srchstr); #" # splits terms by " marks first
	my @srchterms;               

	for (my $i = 0; $i < @buff; $i++) { #splits terms into individual words
		if ($i % 2 == 0) { 				#when not surrounded by " marks
			push (@srchterms, split(/\s+/, $buff[$i]));
		} else {
			push (@srchterms, $buff[$i]);
		}
	}

	foreach my $term (@srchterms) { #surround with % signs.
		$term =~ s/^(.+)$/%$1%/g;
	}

	return @srchterms;
}

sub makeNav { 	#constructs a navbar (< Prev | x to x | Next >)
	my ($type, $start, $extra, $total) = @_;
	my ($prevstart, $nextstart, $thispage);

	my $limit;
	if ($type eq 'index') {
		$limit = items_per_page;
		$extra = "item=search&srchstr=" . $extra;
	} elsif ($type eq 'comments') {
		$limit = comments_per_page;
		$extra = "item=" . $extra;
	}

	if (!$start) { 
		$prevstart = 'n';
		$start = 0;
	} elsif (($start - $limit) <= 0) {
		$prevstart = 0;
	} else {
		$prevstart = $start - $limit;
	}
	if (($start + $limit) == $total) {
		$nextstart = 'n';
		$thispage = $limit;
	} elsif (($start + $limit) > $total) {
		$nextstart = 'n';
		$thispage = $total - $start;
	} else {
		$nextstart = $start + $limit;
		$thispage = $limit;
	}
	my $nav = '';
	if ($prevstart ne 'n') {
		$nav = $nav . "<a href=\"grammar.pl?" . $extra;
		$nav = $nav . "&start=" . $prevstart . "\">&lt; Prev</a>";
	}
	$nav = $nav . " | " . ($start + 1) . " to " . ($start + $thispage) . " | "; 
	if ($nextstart ne 'n') {
		$nav = $nav . "<a href=\"grammar.pl?" . $extra;
		$nav = $nav . "&start=" . $nextstart . "\">Next &gt;</a>";
	}

	return ($nav, $thispage);
}


sub prelim {
	my $query = new CGI;
	my %params = $query->Vars;				#grab get/post data

	if ($params{item} =~ m/^\d+$/) {	#viewing comment (integer item)
		getComment($params{item}, $params{start});
	} elsif ($params{item} eq 'search' || (!%params)) {	#search page
		getIndex($params{srchstr}, $params{start});
	} elsif ($params{method} eq 'itm') {	#adding a comment
		if (disable_posting != 1) {
			postComment($params{itm}, $params{body});
		} else {
			print "Sorry, posting comments is disabled! :(";
		}
	} elsif ($params{method} eq 'idx') {	#adding an index entry
		if (disable_posting == 0) {
			postIndex($params{def1}, $params{def2}, $params{alch});
		} else {
			print "Sorry, posting entries is disabled! :(";
		}
	} else {
		die "Unknown get/post info";
	}
}

prelim;
