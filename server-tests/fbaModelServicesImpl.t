use FindBin qw($Bin);
use lib $Bin.'/../lib';
use lib $Bin.'/../../workspace_service/lib/';
use lib $Bin.'/../../kb_seed/lib/';
use lib $Bin.'/../../idserver/lib/';
use lib "/kb/deployment/lib/perl5/site_perl/5.16.0/Bio/";
use lib "/kb/deployment/lib/perl5/site_perl/5.16.1/";
use Bio::KBase::workspace::Client;
use LWP::Simple qw(getstore);
use IO::Compress::Gzip qw(gzip);
use IO::Uncompress::Gunzip qw(gunzip);
use Bio::KBase::fbaModelServices::Impl;
use JSON::XS;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Temp qw(tempfile);
my $test_count = 17;

#Logging in
my $tokenObj = Bio::KBase::AuthToken->new(
    user_id => 'kbasetest', password => '@Suite525'
);
my $token = $tokenObj->token();

#Instantiating client workspace
my $ws = Bio::KBase::workspace::Client->new("http://140.221.84.209:7058");
$ws->{token} = $token;
$ws->{client}->{token} = $token;
$ENV{KB_SERVICE_NAME}="fbaModelServices";
#$ENV{KB_DEPLOYMENT_CONFIG}=$Bin."/../configs/test.cfg";
my $obj = Bio::KBase::fbaModelServices::Impl->new({workspace => $ws});
################################################################################
#Tests 1-3: retrieving a biochemistry object and reaction and compound data
################################################################################
#Testing biochemistry retrieval method
my $biochemistry = $obj->get_biochemistry({});
ok defined($biochemistry), "Successfully printed biochemistry!";

#Testing reaction retrieval method
my $rxns = $obj->get_reactions({
	reactions => ["rxn00001","rxn00002"],
});
ok defined($rxns->[0]), "Successfully printed reactions!";

#Testing compound retrieval method
my $cpds = $obj->get_compounds({
	compounds => ["cpd00001","cpd00002"]
});
ok defined($cpds->[0]), "Successfully printed compounds!";
################################################################################
#Tests 4: adding a genome object to the database
################################################################################
my $genome = $obj->genome_to_workspace({
	genome => "kb|g.0",
	workspace => "fbaservicestest"
});
ok defined($genome), "Successfully loaded genome object to workspace!";
my $phenos = $obj->import_phenotypes({
	workspace => "fbaservicestest",
	genome => $genome->[0],
	genome_workspace => "fbaservicestest",
	phenotypes => [
		[[],"CustomMedia","fbaservicestest",["ADP"],1],
		[[],"Complete","fbaservicestest",["H2O"],1],
		[["kb|g.0.peg.1","kb|g.0.peg.2"],"CustomMedia","fbaservicestest",[],1]
	],
	notes => ""
});
################################################################################
#Tests 5-7: adding and retrieving a media formulation
################################################################################
#Now adding media formulation to workspace
my $media = $obj->addmedia({
	media => "CustomMedia",
	workspace => "fbaservicestest",
	name => "CustomMedia",
	isDefined => 1,
	isMinimal => 1,
	type => "Minimal media",
	compounds => ["H2O","cpd00002","ADP"],
	concentrations => [0.001,0.001,0.001],
	maxflux => [1000,1000,1000],
	minflux => [-1000,-1000,-1000]
});
ok defined($media), "Media successfully added to workspace!";
$media = $obj->addmedia({
	media => "Complete",
	workspace => "fbaservicestest",
	name => "Complete",
	isDefined => 0,
	isMinimal => 0,
	type => "Rich media",
	compounds => [],
	concentrations => [],
	maxflux => [],
	minflux => []
});

#Now exporting media formulation
my $html = $obj->export_media({
	media => $media->[0],
	workspace => "fbaservicestest",
	format => "html",
});
ok defined($html), "Successfully exported media to html format!";

#Testing media retrieval method
my $medias = $obj->get_media({
	medias => ["CustomMedia"],
	workspaces => ["fbaservicestest"],
});
ok defined($medias->[0]), "Successfully printed media!";
################################################################################
#Test 8-12: building and exporting an metabolic model
################################################################################
#Now test ability to produce a metabolic model
my $model = $obj->genome_to_fbamodel({
	genome => $genome->[0],
	workspace => "fbaservicestest",
	#coremodel => 1
});
ok defined($model), "Model successfully constructed from input genome!";
#Testing model export
#my $cytoseed = $obj->export_fbamodel({
#	model => $model->[0],
#	workspace => "fbaservicestest",
#	format => "cytoseed"
#});
#ok defined($cytoseed), "Successfully exported model to cytoseed format!";

$html = $obj->export_fbamodel({
	model => $model->[0],
	workspace => "fbaservicestest",
	format => "html"
});
ok defined($html), "Successfully exported model to html format!";

my $sbml = $obj->export_fbamodel({
	model => $model->[0],
	workspace => "fbaservicestest",
	format => "sbml"
});
ok defined($sbml), "Successfully exported model to sml format!";

my $mdls = $obj->get_models({
	models => [$model->[0]],
	workspaces => ["fbaservicestest"],
});
ok defined($mdls->[0]), "Successfully printed model data!";

################################################################################
#Test 13-15: importing a phenotypes set, simulating phenotypes, and export simulation results
################################################################################
#Now test phenotype import
$phenos = $obj->import_phenotypes({
	workspace => "fbaservicestest",
	genome => $genome->[0],
	genome_workspace => "fbaservicestest",
	phenotypes => [
		[[],"CustomMedia","fbaservicestest",["ADP"],1],
		[[],"Complete","fbaservicestest",["H2O"],1],
		[["kb|g.0.peg.1","kb|g.0.peg.2"],"CustomMedia","fbaservicestest",[],1]
	],
	notes => ""
});
ok defined($phenos), "Successfully imported phenotypes!";

#Now test phenotype simulation
my $phenosim = $obj->simulate_phenotypes({
	model => $model->[0],
	model_workspace => "fbaservicestest",
	phenotypeSet => $phenos->[0],
	workspace => "fbaservicestest",
	formulation => {},
	notes => "",
});
ok defined($phenosim), "Successfully simulated phenotypes!";

#Now test phenotype simulation export
$html = $obj->export_phenotypeSimulationSet({
	phenotypeSimulationSet => $phenosim->[0],
	workspace => "fbaservicestest",
	format => "html"
});
ok defined($html), "Successfully exported phenotype simulations to html format!";

################################################################################
#Test 6: runfba, gapfill, and gapgen
################################################################################
#Now test flux balance analysis
my $fba = $obj->runfba({
	model => $model->[0],
	model_workspace => "fbaservicestest",
	formulation => {
		media => "CustomMedia",
		media_workspace => "fbaservicestest"
	},
	fva => 0,
	simulateko => 0,
	minimizeflux => 0,
	findminmedia => 0,
	notes => "",
	workspace => "fbaservicestest"
});
ok defined($fba), "FBA successfully run on input model!";

#Testing fba retrieval method
my $fbas = $obj->get_fbas({
	fbas => [$fba->[0]],
	workspaces => ["fbaservicestest"],
});
ok defined($fbas->[0]), "Successfully printed fba data!";

#Now test flux balance analysis export
$html = $obj->export_fba({
	fba => $fba->[0],
	workspace => "fbaservicestest",
	format => "html"
});
ok defined($html), "Successfully exported FBA to html format!";

##Now running queued gapfill job mannually to ensure that the job runs and postprocessing works
#$job = $obj->run_job({
#	job => $job->{id},
#	workspace => "testworkspace"
#});
#ok defined($job), "Successfully ran queued gapfill job!";
#
##Now queuing gapfilling in custom media
#$job = $obj->queue_gapfill_model({
#	model => $model->[0].".gf",
#	workspace => "testworkspace",
#	formulation => {
#		formulation => {
#			media => "Complete",
#			media_workspace => "NO_WORKSPACE"
#		},
#		num_solutions => 1
#	},
#	integrate_solution => 1,
#	out_model => $model->[0].".gf2",
#	donot_submit_job => 1
#});
#ok defined($html), "Successfully queued gapfill job!";
#
##Now running queued gapfill job mannually to ensure that the job runs and postprocessing works
#$job = $obj->run_job({
#	jobid => $job->{id},
#	workspace => "testworkspace"
#});
#ok defined($job), "Successfully ran queued gapfill job!";

##Now test flux balance analysis
#$fba = $obj->runfba({
#	model => $model->[0].".gf2",
#	model_workspace => "testworkspace",
#	formulation => {
#		media => "CustomMedia",
#		media_workspace => "testworkspace"
#	},
#	fva => 0,
#	simulateko => 0,
#	minimizeflux => 0,
#	findminmedia => 0,
#	notes => "",
#	workspace => "testworkspace"
#});
#ok defined($fba), "FBA successfully run on gapfilled model!";
#
##Now exporting queued FBA
#$html = $obj->export_fba({
#	fba => $fba->[0],
#	workspace => "testworkspace",
#	format => "html"
#});
#ok defined($html), "Successfully exported FBA to html format!";

##Now exporting queued FBA
#$job = $obj->queue_gapgen_model({
#	model => $model->[0].".gf2",
#	workspace => "testworkspace",
#	formulation => {
#		formulation => {
#			media => "CustomMedia",
#			media_workspace => "testworkspace"
#		},
#		refmedia => "Complete",
#		refmedia_workspace => "NO_WORKSPACE",
#		num_solutions => 1
#	},
#	integrate_solution => 1,
#	out_model => $model->[0].".gg",
#	donot_submit_job => 1
#});
#ok defined($html), "Successfully queued gapgen job!";
#Now checking job retreival
##Now running queued gapfill job mannually to ensure that the job runs and postprocessing works
#$job = $obj->run_job({
#	job => $job->{id},
#	workspace => "testworkspace"
#});
#ok defined($job), "Successfully ran queued gapgen job!";
#
##Now test flux balance analysis
#$fba = $obj->runfba({
#	model => $model->[0].".gg",
#	model_workspace => "testworkspace",
#	formulation => {
#		media => "CustomMedia",
#		media_workspace => "testworkspace"
#	},
#	fva => 0,
#	simulateko => 0,
#	minimizeflux => 0,
#	findminmedia => 0,
#	notes => "",
#	workspace => "testworkspace"
#});
#ok defined($fba), "FBA successfully run on gapgen model!";

##Now exporting queued FBA
#$html = $obj->export_fba({
#	fba => $fba->[0],
#	workspace => "testworkspace",
#	format => "html"
#});
#ok defined($html), "Successfully exported FBA to html format!";

## check for error messages from tests
#if ($return) {
#   print $return;
#   exit(100);
#}

done_testing($test_count);