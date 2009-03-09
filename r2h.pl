#!/usr/local/bin/perl

# This code produces a webpage that takes romanized hangul input and returns
# actual hangul unicode HTML character entities.  Details on the actual
# webpage.
#
# Written by William D. Lipe in 2005
# This code is hereby released into the public domain, no rights reserved.

use warnings;
use strict;

binmode(STDOUT, ":utf8");

print "Content-type: text/html\n\n";

sub r2hSyl { #returns a unicode character for a hangeul syllable
	my ($syl) = @_;
	my $hanint = 0xAC00;

	my $cc = "[gkndtlrmbpsjch]";		 #korean consonants
	my $vc = "[aeiouwy]";				 #korean vowels

	#lists of every possible combination, in numerical order
	my @initial = split(',','g,kk,n,d,tt,l,m,b,pp,s,ss,,j,jj,ch,k,t,p,h');
	my @vowel = split(',','a,ae,ya,yae,eo,e,yeo,ye,o,wa,wae,oe,yo,u,wo,we,wi,yu,eu,ui,i');
	my @final = split(',',',g,gg,gs,n,nj,nh,d,l,lk,lm,lb,ls,lt,lp,lh,m,b,bs,s,ss,ng,j,ch,k,t,p,h');

	$syl =~ s/r/l/ig;

	#should match a valid korean syllable
	if ($syl !~ m/(${cc}{0,2})(${vc}{1,3})(${cc}{0,2})/i) {
		die $syl;
	}

	my ($n1, $n2, $n3) = ($1, $2, $3);

	foreach (@initial) {
		last if ($n1 eq $_);
		$hanint += 0x24C;
	}
	
	foreach (@vowel) {
		last if ($n2 eq $_);
		$hanint += 0x01C;
	}

	foreach (@final) {
		last if ($n3 eq $_);
		$hanint += 0x1;
	}

	return chr($hanint);

}

sub r2hStr { #returns a string of hangeul unicode characters
	my ($str) = @_;

	my $vc = "[aeiouwy]";				#korean vowels

	my $v =								#matches all vowel combinations
	"[wy]?(a(?!e)".
	"|(?<!((?<![wy])[oa]))e(?!(o|u(?!i)))".
	"|(?<!((?<![wy])u))i".
	"|(?<!((?<!w)e))o(?!e)".
	"|(?<![wy])u(?!i)".
	"|ae|(?<!w)eo".
	"|(?<![wy])eu(?!i)".
	"|(?<![wy])ui|(?<![wy])oe".
	"|yo|yu|ye|we|wo)";
	
	my $c1 =							#matches initial consonant combinations
	"(g|n|d|l|r|m|b|(?<!c)h|ch".
	"|(?<!k)k".
	"|(?<!(l|r|${vc}))kk".
	"|(?<=(?<=(l|r|${vc}))k)k".
	"|(?<!t)t".
	"|(?<!(l|r|${vc}))tt".
	"|(?<=(?<=(l|r|${vc}))t)t".
	"|(?<!p)p".
	"|(?<!(l|r|${vc}))pp".
	"|(?<=(?<=(l|r|${vc}))p)p".
	"|(?<!j)j".
	"|(?<!(n|${vc}))jj".
	"|(?<=(?<=(n|${vc}))j)j".
	"|(?<!s)s".
	"|(?<!((?<!s)s|b|g|${vc}))ss".
	"|(?<=(?<=(s|b|g|${vc}))s)s)";
	
	my $c2 =							#matches final consonant combinations
	"((gg|gs|nj|nh|[lr]k|[lr]m|[lr]b|[lr]s|[lr]t|[lr]p|[lr]h|bs|ss|ch|ng)(?!${vc})".
	"|(g|n|d|r|l|m|b|s|j|t|p|h|k)(?!${vc}))";

	$str =~ s/(${c1}?${v}${c2}?)/r2hSyl($1)/ige;
	$str =~ s/(-|')//g; #'

	return $str;

}

sub frontend {
	use CGI;

	my $query = new CGI;
	my %params = $query->Vars;

	my $str = $params{body};
	$str = '' if !$str;

	$str =~ s/&/&amp\;/g; 
	$str =~ s/</&lt\;/g;
	$str =~ s/>/&gt\;/g;
	$str =~ s/"/&quot;/g; #"
	$str =~ s/'/&#39;/g; #'
	$str =~ s/,/&#44;/g;

	my $newstr;

	if (length($str) > 1000) {
		$newstr = "String too long.\n";
	} else {
		$newstr = r2hStr($str);
	}

	print q`
<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Hangeul Generator</title>
</head><body>
<h1>Hangeul Generator</h1>
<p><h2>How to use:</h2>
<p>Simply type romanized Korean into the box below, and click submit, and it will output hangeul characters.  
The romanization used here is modeled almost exactly after 
<a href="http://english.president.go.kr/warp/en/korea/language/revise/romanization.html">the revised romanization
of Korean</a>, with a few exceptions.
<ul>
<li><strong>You have to write the literal characters used.</strong>
<p>In other words, to get ` . r2hStr("mueos") . q` you have to write <em>mueos</em> and not <em>mueot</em>, 
despite how it ends up sounding.
<p>Also, you have to write unaspirated consonants as <em>g d j</em> and <em>b</em>, 
even at the end of a syllable or a word.
<li><strong>Use a - or ' to separate syllables, if you need to.</strong>
<p>The script makes certain assumptions about syllable boundaries.  As a general rule, 
it favors initial consonants first, then one initial and one final, then double finals with an initial, 
then double initial and double final.  
In other words, if you want to get ` . r2hStr("mueos'eun") . q`, you have to write 
<em>mueos'eun</em>.  Otherwise, you'll end up with ` . r2hStr("mueoseun") . q`.</ul>
<p>Results:
<table border=5><tr><td>
` . $newstr . q`</tr></table>
<p>Try it:<br>
<form method="post" action="r2h.pl">
<textarea rows=8 cols=80 name="body"></textarea>
<br><input type="submit" value="send"></form>
</body></html>
`;

}

&frontend;
