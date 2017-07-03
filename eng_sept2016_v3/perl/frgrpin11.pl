#!/usr/bin/perl -w
use strict;
{
use HTML::TableExtract;
use Data::Dumper;
use feature 'say';
#main routine
#processing groups for sept 2016 version
my $dir = "./sept2016_classes_html/";
my $errcnt=0;
my @index=&read_index;
my $i=0;
my $alldir = "./";
my $outall = "all_eng_classes_sept2016.xml";
open(my $OUTALL,">$alldir"."$outall") || die "can't open for output $outall\n";
print $OUTALL "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
print $OUTALL "<CLASSES>\n";

while ($index[$i]) {
    print "$index[$i]\n";
    my $outdir = "./sept2016_classes_xml/";
    my $infile = $index[$i];
    $infile =~ s/\(/\\\(/g ;
    $infile =~ s/\)/\\\)/g ;
    print $infile."\n";
    my $clean = "tr -cd '\11\12\15\40-\176' > $dir" . "cleanfile.html < $dir" . "$infile";
    print $clean."\n";
    system($clean);
    my $htmlin = &getcontent("$dir" . "cleanfile.html");
    #my $htmlin = &getcontent("$dir" . "$index[$i]");
    my $outfile = $index[$i];
    $outfile =~ s/\.html/\.xml/;
    open(my $OUTFILE,">$outdir"."$outfile") || die "can't open for output $outfile\n";
    print $OUTFILE "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
    #print $OUTFILE "<CLASS>\n";
    &html2xml($htmlin,$OUTFILE);
    #print $OUTFILE "</INTERACTIONS>\n";
    close($OUTFILE);
    #die;
    $htmlin='';
    system("rm $dir"."cleanfile.html");
    $i++;
}
print $OUTALL "</CLASSES>";
close($OUTALL);
#end main routine
print "Error Count: $errcnt\n";

sub html2xml {
    my $te = HTML::TableExtract->new();
    my $content=shift;
    my $OUTFILE=shift;

    $te->parse( $content );

    foreach my $ts ( $te->tables() )
    {
	#say Dumper($ts);
	#my $redrug = qr/Drug:\W([\w,-, ,\(,\)]*)\n*/;
	my $redrug = qr/\s*[[Drug][:,;]]*\W*([\S, ]*)\s*\n*/;
	my $redrug2 = qr/\s*\W*([\S, ]*)\s*\n*/;
	my $rebrxn = qr/Rx[ ]*No[r]*m[ ]*:\W*[0-9]*\W*\s*/;
	my $rerxn = qr/R[x,X][ ]*[N,n]o[r]*m[ ]*:\W*([0-9]*)\W*\s*/;
	my $rebatc = qr/ATC:\W*[A-Z,0-9]{4,8}/;
	my $reatc = qr/ATC:\W*([A-Z,0-9]+)/;
	my $reatc2 = qr/\s*([A-Z,0-9]+)\W*/;
	my $rebclassname = qr/CLASS:\W*\S+\s*\n*/;
	my $reclassname = qr/\s*CLASS:\W*(.*)\n*/;
	my $rebclass = qr/CLASS CODE:\W*[\w\-]+/;
	my $reclass = qr/CLASS CODE[:]*\W*([\w\-]+)/;
	my $reany = qr/([\s\S]*)/;
	my $first = 1; 
	foreach my $row ( $ts->rows() )
	{
	    my $drug = $row->[0];
	    #print "row: $drug\n";
	    if ($first) {
		#print "first drug: $drug\n";
		$drug =~ /$reclassname+\s*$reclass+\s*/;
		my $name = $1;
		my $classcode = $2;
		print "\n***CLASS***\n";
		if ($name) {
		    print $OUTFILE "<CLASS name=\"$name\" code=\"$classcode\">\n";
		    print $OUTALL "<CLASS name=\"$name\" code=\"$classcode\">\n";
		    print $OUTFILE "<SOURCE>\n";
		    print $OUTALL "<SOURCE>\n";
		    print $OUTFILE "<CLINICAL_SOURCE>ANSM</CLINICAL_SOURCE>\n";
		    print $OUTALL "<CLINICAL_SOURCE>ANSM</CLINICAL_SOURCE>\n";
		    print $OUTFILE "<SOURCE_FILE>$index[$i]</SOURCE_FILE>\n";
		    print $OUTALL "<SOURCE_FILE>$index[$i]</SOURCE_FILE>\n";
		    print $OUTFILE "</SOURCE>\n";
		    print $OUTALL "</SOURCE>\n";
		    print "CLASS NAME= $name\n";
		    print "CODE= $classcode\n";
		} else {print "Error - name not found - ".$drug."\n"; $errcnt++;}
		$first = 0;
	    } else {
		$drug =~ /$redrug+\s*$rerxn+\s*$reany*/;
		my $name = $1;
		my $rxn = $2;
		if ($name) {
		    print "drug: ".$name." RxNorm: ".$rxn."\n";		
		    print $OUTFILE "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
		    print $OUTALL "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
		} else {
		    my @resolve = split(/\n/,$drug);
		    $resolve[0] =~ /[Drug: ]*(.*)/;
		    #$name = $resolve[0];
		    $name = $1;
		    if ($resolve[2] =~ /.*R[x,X].*/) {
			$resolve[2] =~ /$rerxn\s*/;
			$rxn = $1;
			print "drug: ".$name." RxNorm: ".$rxn."\n";		
			print $OUTFILE "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
			print $OUTALL "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
		    } else {
			if ($resolve[4] =~ /.*Rx.*/) {
			    $resolve[4] =~ /$rerxn\s*/;
			    $rxn = $1;
			    #$rxn = $resolve[4];
			    print "drug: ".$name." RxNorm: ".$rxn."\n";		
			    print $OUTFILE "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
			    print $OUTALL "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
			} else {
			    if ($resolve[6] =~ /.*Rx.*/) {
				$resolve[6] =~ /$rerxn\s*/;
				$rxn = $1;
				#$rxn = $resolve[6];
				print "drug: ".$name." RxNorm: ".$rxn."\n";		
				print $OUTFILE "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
				print $OUTALL "<DRUG name=\"".$name."\" rxnorm=\"".$rxn."\">\n";
			    } else {
				if ($name) {
				    print $OUTFILE "<DRUG name=\"$name\" >\n";
				    print $OUTALL "<DRUG name=\"$name\" >\n";
				    print "ERROR - Drug with no codes: $name\n";
				    $errcnt++;
				} else {
				    print "ERROR - name not found - ".$drug."\n";
				    $errcnt++;
				    next;
				    say Dumper($drug);
				    say Dumper(@resolve);
				}
			    }
			}
		    }
		}
		if ($name) {
		    #print "what's left: $3\n";
		    $drug =~ /(.*)ATC: +(.*)/;
		    my $rightofatc = $2;
		    #print "right of atc: $rightofatc\n";
		    $rightofatc =~ /\s*([n,N]ot found)\s*/; 
		    if ($1) {$rightofatc = '';}
		    $rightofatc =~ /\s*([n,N]one found)\s*/; 
		    if ($1) {$rightofatc = '';}
		    if ($rightofatc) {
			$rightofatc =~ s/ATC:/ /;
			my @atc = split(/ +/,$rightofatc);
			my $i = 0;
			while ($atc[$i]) {
			    print $OUTFILE "<ATC code=\"".$atc[$i]."\" />\n";
			    print $OUTALL "<ATC code=\"".$atc[$i]."\" />\n";
			    print "ATC: ".$atc[$i]."\n";
			    $i++;
			}
		    }
		    print $OUTFILE "</DRUG>\n";
		    print $OUTALL "</DRUG>\n";
		    #say Dumper(@atc);
		}
	    }
	}
	print $OUTFILE "</CLASS>\n";
	print $OUTALL "</CLASS>\n";
	$te = '';
	$content = '';
    }
}
sub oldstuff {
#		print "everything: $drug\n";
#		$drug =~ /$redrug+\s*$rerxn+\s*$reany*/;
#		my $name = $1;
#		my $rxn = $2;
#		my $atc = $3;
#		print "drug: $name RxNorm: $rxn";
#		print "\natc: $atc\n";
#		$atc = $drug;
#		if ($atc) {
#		    $atc =~ /$reatc*$reatc2*/;
#		    #$atc =~ /\s*ATC: $reatc2{1}\s*$reany*/;
#		    my $oneatc = $1;
#		    print "ATC: $oneatc";
#		    $atc = $2;
#		}
#		print "\n";
}
sub read_index {
    my @index;
    open(INDEX,"< $dir" . "index") || die "can't open index";
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
