use FindBin qw($Bin);
use lib $Bin.'/../lib';
use fbaModelServicesImpl;
use JSON::XS;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
my $test_count = 7;

my $obj = fbaModelServicesImpl->new();
open(GENOMEFILE, "<", $Bin."/../data/myGenome.annotated")
  or die "could not open $Bin/../data/myGenome.annotated";
my @input_txt = <GENOMEFILE>;
close(GENOMEFILE);
my $json = JSON::XS->new;
my $gen = $json->decode(join("\n",@input_txt));
my $mod = $obj->genome_to_fbamodel($gen);
ok defined($mod), "genome_to_fbamodel should return a model!";
ok defined($mod->{uuid}), "genome_to_fbamodel should return a model with a uuid!";
my $html = $obj->object_to_html({objectType => "Model",id => "model/kbase/kb|fm.82"});
ok defined($html), "object_to_html should return an html file!";
my $sbml = $obj->fbamodel_to_sbml({objectType => "Model",id => "model/kbase/kb|fm.82"});
ok defined($sbml), "fbamodel_to_sbml should return an sbml file!";
ok $sbml =~ m/Buchnera/, "fbamodel_to_sbml should return an sbml file with the organism name in it!";
my $gfmod = $obj->gapfill_fbamodel($mod,{media => "Media/name/Carbon-D-Glucose"},1,"");
ok defined($gfmod), "gapfill_fbamodel should return a model!";
my $fba = $obj->runfba($gfmod,{media => "Media/name/Carbon-D-Glucose"},0,"");
ok defined($fba), "runfba should return an fba result!";

done_testing($test_count);
