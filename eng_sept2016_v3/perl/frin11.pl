#!/usr/bin/perl -w
use strict;
{
use HTML::TableExtract;
use HTML::Entities;
use Data::Dumper;
use feature 'say';

#main routine
my $interactioncount = 0;
my $errorcount = 0;
my $dir = "./sept2016_tables_html/";
my $alldir = "./";
my $outall = "all_eng_tables_sept2016.xml";
open(my $OUTALL,">$alldir"."$outall") || die "can't open for output $outall\n";
print $OUTALL "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
print $OUTALL "<INTERACTIONS>\n";


my @index=&read_index;
my $i=0;
while ($index[$i]) {
    print "$index[$i]\n";
    #my $dir = "../eng_tables2015-html/";
    my $outdir = "./sept2016_tables_xml/";
    my $infile = $index[$i];
    $infile =~ s/\(/\\\(/g ;
    $infile =~ s/\)/\\\)/g ;
    my $clean = "tr -cd '\11\12\15\40-\176' > $dir" . "cleanfile.html < $dir" . "$infile";
    system($clean);
    #my $htmlin = &getcontent("$dir" . "$index[$i]");
    my $htmlin = &getcontent("$dir" . "cleanfile.html");
    my $outfile = $index[$i];
    $outfile =~ s/\.html/\.xml/;
    open(my $OUTFILE,">$outdir"."$outfile") || die "can't open for output $outfile\n";
    print $OUTFILE "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
    print $OUTFILE "<INTERACTIONS>\n";
    &html2xml($htmlin,$OUTFILE);
    print $OUTFILE "</INTERACTIONS>\n";
    close($OUTFILE);
    $htmlin='';
    system("rm $dir"."cleanfile.html");
    $i++;
}
print $OUTALL "</INTERACTIONS>";
close($OUTALL);

print "$interactioncount Interactions Processed\n";
print "***** Only $errorcount Errors!\n";
#end main routine

sub html2xml {
    my $te = HTML::TableExtract->new();
    my $content=shift;
    my $OUTFILE=shift;
    #$content =~ tr/\000-\037/ /;
    #$content =~ tr/\040-\176/ /c;
    $te->parse( $content );

    foreach my $ts ( $te->tables() )
    {
	#say Dumper($ts);
	foreach my $row ( $ts->rows() )
	{
	    $interactioncount++;
	    my $drug1 = $row->[0];
	    print "\n***interaction***\n";
	    print $OUTFILE "<INTERACTION>\n";
	    print $OUTALL "<INTERACTION>\n";
	    print $OUTFILE "<SOURCE>\n";
	    print $OUTALL "<SOURCE>\n";
	    print $OUTFILE "<CLINICAL_SOURCE>ANSM</CLINICAL_SOURCE>\n";
	    print $OUTALL "<CLINICAL_SOURCE>ANSM</CLINICAL_SOURCE>\n";
	    print $OUTFILE "<SOURCE_FILE>$index[$i]</SOURCE_FILE>\n";
	    print $OUTALL "<SOURCE_FILE>$index[$i]</SOURCE_FILE>\n";
	    print $OUTFILE "</SOURCE>\n";
	    print $OUTALL "</SOURCE>\n";
	    print "drug1\n";
	    print $OUTFILE "<DRUG1>\n"; 
	    print $OUTALL "<DRUG1>\n"; 
	    &parsedrug($drug1,$OUTFILE);
	    print $OUTFILE "</DRUG1>\n";
	    print $OUTALL "</DRUG1>\n";
	    my $drug2 = $row->[1];
	    print "drug2\n";
	    print $OUTFILE "<DRUG2>\n";
	    print $OUTALL "<DRUG2>\n";
	    &parsedrug($drug2,$OUTFILE);
	    print $OUTFILE "</DRUG2>\n";
	    print $OUTALL "</DRUG2>\n";
	    my $interaction = $row->[2];
	    if ($interaction) {
		print "$interaction\n";
		my $encinter = encode_entities($interaction);
		print $OUTFILE "<DESCRIPTION>$encinter</DESCRIPTION>\n";
		print $OUTALL "<DESCRIPTION>$encinter</DESCRIPTION>\n";
	    } else {
		print "ERROR - missing interaction text\n";
		say Dumper($interaction);
		$errorcount++;
	    }
	    my $commentstr = $row->[3];
	    #say Dumper($commentstr);
	    if ($commentstr) {
		$commentstr =~ /(.*)\n*(.*)/;
		my $severity = $1;
		my $comment = $2;
		if ($severity) {
		    print "severity: $severity\n";
		    print $OUTFILE "<SEVERITY>$severity</SEVERITY>\n";
		    print $OUTALL "<SEVERITY>$severity</SEVERITY>\n";
		} else {
		    print "ERROR - missing Severity\n";
		    say Dumpster($commentstr) ;
		    $errorcount++;
		}
		if ($comment) {
		    print "$comment\n";
		    print $OUTFILE "<COMMENT>$comment</COMMENT>\n";
		    print $OUTALL "<COMMENT>$comment</COMMENT>\n";
		}
	    }
	    print $OUTFILE "</INTERACTION>\n";
	    print $OUTALL "</INTERACTION>\n";
	}
	$te = '';
	$content = '';
    }
}
sub parsedrug {
    my $rebrxn = qr/Rx[ ]*Norm:\W[0-9]+\W*/;
    my $rerxn = qr/Rx[ ]*Norm:\W([0-9]+)\W*/;
    #my $rebrxn = qr/Rx[ ]*Norm[ ]*:\W*[0-9]*\W*\s*/;
    #my $reany = qr/([\w\W]*)/;
    my $reany = qr/([\s\S]*)/;
    #my $rebatc = qr/ATC:\W*\w{7}/;
    #my $reatc = qr/ATC:\W*(\w+)/;
    #my $reatc2 = qr/\s*(\w{7})/;
    #my $rebatc = qr/ATC:\W*[A-Z,0-9]{4,8}/;
    my $rebatc = qr/ATC:.*[A-Z,0-9]{4,8}/;
    #my $reatc = qr/ATC:\W*([A-Z,0-9]+)/;
    my $reatc = qr/ATC:.*([A-Z,0-9]+)/;
    my $reatc2 = qr/\s*([A-Z,0-9]{4,8})/;
    my $rebclass = qr/CLASS CODE:\W*[\w\-]+/;
    my $reclass = qr/CLASS CODE:\W*([\w\-]+)/;
    my $rebgroup = qr/GROUP[ ]*ID:\s*[\w\-]+/;
    my $regroup = qr/GROUP[ ]*ID:\s*([\w\-]+)/;
    my $d = shift; 
    my $OUTFILE = shift;
    #$d =~ /(.*)\n\s*($rebrxn*)\s*($rebclass*)\s*($rebatc*)\s*($reany*)/;
    if ($d) {
	#$d =~ /(.*)\s*($rebrxn*)\s*($rebclass*)\s*($rebatc*)\s*($reany*)/;
	$d =~ /(.*)\s*($rebrxn*)\s*($rebclass*)\s*($rebgroup*)\s*($rebatc*)\s*($reany*)/;
	my $name = $1;
	#say Dumper($d);
	#say Dumper($name);
	chomp($name);
	chomp($name);
	if (not $1) { 
	    print "ERROR PARSING NAME\n";
	    say Dumpster($d);
	    $errorcount++;
	}
	my $rxnstring = $2;
	my $classtring = $3;
	my $groupstring =$4;
	my $atcstring = $5;
	my $moreatc = $6;
	my $isdrug = 0;
	"a" =~ /a/;
	if ($rxnstring) {
	    $isdrug = 1;
	} else {
	    if ($classtring) {
	    } else {
		if ($groupstring) {
		} else {
		    my @resolve = split(/\n/,$d);
		    $name = $resolve[0];
		    if ($resolve[2] =~ /.*R[x,X].*/) {
			$rxnstring = $resolve[2];
			$atcstring = '';
			$moreatc = $resolve[4];
			$isdrug = 1;
		    } else {
			if ($resolve[4] =~ /.*Rx.*/) {
			    $rxnstring = $resolve[4];
			    $atcstring = '';
			    $moreatc = $resolve[6];
			    $isdrug = 1;
			} else {
			    if ($name) {
				$isdrug = 1;
				print $OUTFILE "<DRUG name=\"$name\" >\n";
				print $OUTALL "<DRUG name=\"$name\" >\n";
				print "Drug with no codes: $name\n";
			    } else {
				print "ERROR no RxNorm or Class\n";
				$errorcount++;
				say Dumper($d);
				say Dumper(@resolve);
			    }
			}
		    }
		}
	    }
	}
	if ($rxnstring) {
	    print "drug name: $name\n";
	    $rxnstring =~ /\s*$rerxn\s*/;
	    my $rxn = $1;
	    print "rxNorm: $rxn\n";
	    print $OUTFILE "<DRUG name=\"$name\" rxcui=\"$rxn\">\n";
	    print $OUTALL "<DRUG name=\"$name\" rxcui=\"$rxn\">\n";
	}
	#say Dumper($classtring);
	##process a class link
	#
	if ($classtring) {
	    if ($classtring) {
		$classtring =~ /$reclass+\s*($reany*)/;
		print "class name: $name\n";
		print "class code: $1\n";
		$classtring = $1;
		print $OUTFILE "<CLASS name=\"$name\" code=\"$classtring\" />";
		print $OUTALL "<CLASS name=\"$name\" code=\"$classtring\" />";
	    }
	}
	if ($groupstring) {
	    if ($groupstring) {
		$groupstring =~ /$regroup+\s*($reany*)/;
		print "class name: $name\n";
		print "class code: $1\n";
		$groupstring = $1;
		print $OUTFILE "<CLASS name=\"$name\" code=\"$groupstring\" />";
		print $OUTALL "<CLASS name=\"$name\" code=\"$groupstring\" />";
	    }
	}
	if ($atcstring) {
	    $atcstring =~ /$reatc2+\s*($reany*)/;
	    print "atc: $1\n";
	    print $OUTFILE "<ATC code=\"$1\" />\n";
	    print $OUTALL "<ATC code=\"$1\" />\n";
	}
	#say Dumper($moreatc);
	#
	my $limit = 0;
	while ($moreatc && $limit++<20) {
	    #$moreatc =~ /($rebatc*)\s*$reatc2*\s*($reany*)\s*/;
	    $moreatc =~ /$reatc2{1}\s*($reany*)\s*/;
	    if ($1) {
		print "more atc: $1\n";
		print $OUTFILE "<ATC code=\"$1\" />\n";
		print $OUTALL "<ATC code=\"$1\" />\n";
	    }
	    #if ($2) {print "more atc2: $2\n"};
	    $moreatc = $2;
	    #say Dumper($moreatc);
	}
	#if ($rxnstring) {print $OUTFILE "</DRUG>\n"};
	if ($isdrug) {print $OUTFILE "</DRUG>\n"};
	#if ($rxnstring) {print $OUTALL "</DRUG>\n"};
	if ($isdrug) {print $OUTALL "</DRUG>\n"};
    }
}
sub read_index {
    my @index;
    open(INDEX,"<./sept2016_tables_html/index") || die "can't open index";
    @index=<INDEX>; #read the whole file
    close(INDEX);
    #say Dumper(@index);
    return @index;
}
sub getcontent {
    my $filepath = shift;
    {
	local $/ = undef; # slurp mode
	open(FILE,"<$filepath") || die "can't open file $filepath\n";
	my $content = <FILE>;
	close(FILE);
        return $content;
    }
}

}
