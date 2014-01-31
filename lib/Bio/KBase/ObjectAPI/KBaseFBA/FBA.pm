########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBA - This is the moose object corresponding to the FBAFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-28T22:56:11
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBA;
package Bio::KBase::ObjectAPI::KBaseFBA::FBA;
use Moose;
use Bio::KBase::ObjectAPI::utilities;

use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBA';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has jobID => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobid' );
has jobPath => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobpath' );
has jobDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobdirectory' );
has command => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, default => '' );
has mfatoolkitBinary => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmfatoolkitBinary' );
has mfatoolkitDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmfatoolkitDirectory' );
has readableObjective => ( is => 'rw', isa => 'Str',printOrder => '30', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreadableObjective' );
has mediaID => ( is => 'rw', isa => 'Str',printOrder => '0', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmediaID' );
has knockouts => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildknockouts' );
has promBounds => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildpromBounds' );
has additionalCompoundString => ( is => 'rw', isa => 'Str',printOrder => '4', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildadditionalCompoundString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildjobid {
	my ($self) = @_;
	my $path = $self->jobPath();
	my $fulldir = File::Temp::tempdir(DIR => $path);
	if (!-d $fulldir) {
		File::Path::mkpath ($fulldir);
	}
	my $jobid = substr($fulldir,length($path."/"));
	return $jobid
}

sub _buildjobpath {
	my ($self) = @_;
	my $path = Bio::KBase::ObjectAPI::utilities::MFATOOLKIT_JOB_DIRECTORY();
	if (!defined($path)) {
		$path = "/tmp/fbajobs/";
	}
	if (!-d $path) {
		File::Path::mkpath ($path);
	}
	return $path;
}

sub _buildjobdirectory {
	my ($self) = @_;
	return $self->jobPath()."/".$self->jobID();
}

sub _buildmfatoolkitBinary {
	my ($self) = @_;
	my $bin;
	if (defined(Bio::KBase::ObjectAPI::utilities::MFATOOLKIT_BINARY()) && length(Bio::KBase::ObjectAPI::utilities::MFATOOLKIT_BINARY()) > 0 && -e Bio::KBase::ObjectAPI::utilities::MFATOOLKIT_BINARY()) {
		$bin = Bio::KBase::ObjectAPI::utilities::MFATOOLKIT_BINARY();
	} else {
		$bin = `which mfatoolkit 2>/dev/null`;
		chomp $bin;
	}
	if ((! defined $bin) || (!-e $bin)) {
		Bio::KBase::ObjectAPI::utilities::error("MFAToolkit binary could not be found!");
	}
	return $bin;
}

sub _buildmfatoolkitDirectory {
	my ($self) = @_;
	my $bin = $self->mfatoolkitBinary();
	if ($bin =~ m/^(.+\/)[^\/]+$/) {
		return $1;
	}
	return "";
}

sub _buildreadableObjective {
	my ($self) = @_;
	my $string = "Maximize ";
	if ($self->maximizeObjective() == 0) {
		$string = "Minimize ";
	}
	foreach my $objid (keys(%{$self->compoundflux_objterms()})) {
		if (length($string) > 10) {
			$string .= " + ";
		}
		$string .= "(".$self->compoundflux_objterms()->{$objid}.") ".$objid;
	}
	foreach my $objid (keys(%{$self->reactionflux_objterms()})) {
		if (length($string) > 10) {
			$string .= " + ";
		}
		$string .= "(".$self->reactionflux_objterms()->{$objid}.") ".$objid;
	}
	foreach my $objid (keys(%{$self->biomassflux_objterms()})) {
		if (length($string) > 10) {
			$string .= " + ";
		}
		$string .= "(".$self->biomassflux_objterms()->{$objid}.") ".$objid;
	}
	if (defined($self->objectiveValue())) {
		$string .= " = ".$self->objectiveValue();
	}
	return $string;
}
sub _buildmediaID {
	my ($self) = @_;
	return $self->media()->id();
}
sub _buildknockouts {
	my ($self) = @_;
	my $string = "";
	my $genekos = $self->geneKOs();
	for (my $i=0; $i < @{$genekos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $genekos->[$i]->id();
	}
	my $rxnstr = "";
	my $rxnkos = $self->reactionKOs();
	for (my $i=0; $i < @{$rxnkos}; $i++) {
		if ($i > 0) {
			$rxnstr .= ", ";
		}
		$rxnstr .= $rxnkos->[$i]->id();
	}
	if (length($string) > 0 && length($rxnstr) > 0) {
		return $string.", ".$rxnstr;
	}
	return $string.$rxnstr;
}
sub _buildpromBounds {
	my ($self) = @_;
	my $bounds = {};
	my $final_bounds = {};
	my $clone = $self->cloneObject();
	$clone->parent($self->parent());
	$clone->prommodel_ref("");
	$clone->fva(1);
	$clone->runFBA();
	my $fluxes = $clone->FBAReactionVariables();
	for (my $i=0; $i < @{$fluxes}; $i++) {
		my $flux = $fluxes->[$i];
		$bounds->{$flux->modelreaction()->reaction()->id()}->[0] = $flux->min();
		$bounds->{$flux->modelreaction()->reaction()->id()}->[1] = $flux->max();
	}
	my $mdlrxns = $self->fbamodel()->modelreactions();
	my $geneReactions = {};
	foreach my $mdlrxn (@{$mdlrxns}) {
		foreach my $prot (@{$mdlrxn->modelReactionProteins()}) {
			foreach my $subunit (@{$prot->modelReactionProteinSubunits()}) {
				foreach my $feature (@{$subunit->features()}) {
					$geneReactions->{$feature->id()}->{$mdlrxn->reaction()->id()} = 1;
				}
			}				
		} 
	}
	my $promModel = $self->promModel();
	my $genekos = $self->geneKOs();
	foreach my $gene (@{$genekos}) {
		my $tfmap = $promModel->queryObject("transcriptionFactorMaps",{
			transcriptionFactor_ref => $gene->_reference()
		});
		if (defined($tfmap)) {
			my $targets = $tfmap->transcriptionFactorMapTargets();
			foreach my $target (@{$targets}) {
				my $offProb = $target->tfOffProbability();
				my $onProb = $target->tfOnProbability();
				my $targetRxns = [keys(%{$geneReactions->{$target->target()->id()}})];
				foreach my $rxn (@{$targetRxns}) {
					my $bounds = $bounds->{$rxn};
					$bounds->[0] *= $offProb;
					$bounds->[1] *= $offProb;
					$final_bounds->{$rxn}->[0] = $bounds->[0];
					$final_bounds->{$rxn}->[1] = $bounds->[1];
				}
			}
		}
	}	

	return $final_bounds;
}
sub _buildadditionalCompoundString {
	my ($self) = @_;
	my $output = "";
	my $addCpds = $self->additionalCpds();
	for (my $i=0; $i < @{$addCpds}; $i++) {
		if (length($output) > 0) {
			$output .= ";";
		}
		$output .= $addCpds->[$i]->name();
	}
	return $output;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 biochemistry

Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry = biochemistry();
Description:
	Returns biochemistry behind FBA object

=cut

sub biochemistry {
	my ($self) = @_;
	$self->fbamodel()->template()->biochemistry();	
}

=head3 genome

Definition:
	Bio::KBase::ObjectAPI::KBaseGenomes::Genome = genome();
Description:
	Returns genome behind FBA object

=cut

sub genome {
	my ($self) = @_;
	$self->fbamodel()->genome();	
}

=head3 mapping

Definition:
	Bio::KBase::ObjectAPI::KBaseOntology::Mapping = mapping();
Description:
	Returns mapping behind FBA object

=cut

sub mapping {
	my ($self) = @_;
	$self->fbamodel()->template()->mapping();	
}

=head3 runFBA

Definition:
	Bio::KBase::ObjectAPI::FBAResults = Bio::KBase::ObjectAPI::FBAFormulation->runFBA();
Description:
	Runs the FBA study described by the fomulation and returns a typed object with the results

=cut

sub runFBA {
	my ($self) = @_;
	if (!-e $self->jobDirectory()."/runMFAToolkit.sh") {
		$self->createJobDirectory();
	}
	system($self->command());
	$self->loadMFAToolkitResults();
	return $self->objectiveValue();
}

=head3 createJobDirectory

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->createJobDirectory();
Description:
	Creates the MFAtoolkit job directory

=cut

sub createJobDirectory {
	my ($self) = @_;
	my $directory = $self->jobDirectory()."/";
	File::Path::mkpath ($directory."reaction");
	File::Path::mkpath ($directory."MFAOutput/RawData/");
	my $translation = {
		drainflux => "DRAIN_FLUX",
		flux => "FLUX",
		biomassflux => "FLUX"
	};
	#Print model to Model.tbl
	my $model = $self->fbamodel();
	my $BioCpd = ["abbrev	charge	deltaG	deltaGErr	formula	id	mass	name"];
	my $mdlcpd = $model->modelcompounds();
	my $cpdhash = {};
	for (my $i=0; $i < @{$mdlcpd}; $i++) {
		my $cpd = $mdlcpd->[$i];
		my $index = $cpd->modelcompartment()->compartmentIndex();
		if (!defined($cpdhash->{$cpd->compound()->id()."_".$index})) {
			my $line = "";
			$cpdhash->{$cpd->compound()->id()."_".$index} = 1;
			my $cols = ["abbreviation","defaultCharge","deltaG","deltaGErr","formula","id","mass","name"];
			for (my $j=0; $j < @{$cols}; $j++) {
				my $function = $cols->[$j];
				if ($j > 0) {
					$line .= "\t";
				}
				if (defined($cpd->compound()->$function())) {	
					$line .= $cpd->compound()->$function();
					if ($index > 0 && $function =~ m/(name)|(id)|(abbreviation)/) {
						$line .= "_".$index;
					}
				}
			}
			push(@{$BioCpd},$line);
		}
	}
	my $rxnhash = {};
	my $BioRxn = ["abbrev	deltaG	deltaGErr	equation	id	name	reversibility	status	thermoReversibility"];
	my $mdlData = ["REACTIONS","LOAD;DIRECTIONALITY;COMPARTMENT;ASSOCIATED PEG"];
	my $mdlrxn = $model->modelreactions();
	for (my $i=0; $i < @{$mdlrxn}; $i++) {
		my $rxn = $mdlrxn->[$i];
		my $direction = $rxn->direction();
		my $rxndir = "<=>";
		if ($direction eq ">") {
			$rxndir = "=>";
		} elsif ($direction eq "<") {
			$rxndir = "<=";
		}
		my $id = $rxn->reaction()->id();
		my $name = $rxn->reaction()->name();
		my $index = $rxn->modelcompartment()->compartmentIndex();	
		if ($index != 0) {
			$id .= "_".$index;
			$name .= "_".$index;
		}
		my $line = $id.";".$rxndir.";".$rxn->modelcompartment()->compartment()->id().";".$rxn->gprString();
		$line =~ s/\|/___/g;
		push(@{$mdlData},$line);
		if (!defined($rxnhash->{$id})) {
			$rxnhash->{$id} = 1;
			my $reactants = "";
			my $products = "";
			my $rgts = $rxn->modelReactionReagents();
			for (my $j=0;$j < @{$rgts}; $j++) {
				my $rgt = $rgts->[$j];
				if ($rgt->coefficient() < 0) {
					my $suffix = "";
					if ($rgt->modelcompound()->modelcompartment()->compartmentIndex() != 0) {
						$suffix .= "_".$rgt->modelcompound()->modelcompartment()->compartmentIndex();
					}
					$suffix .= "[".$rgt->modelcompound()->modelcompartment()->compartment()->id()."]";
					if (length($reactants) > 0) {
						$reactants .= " + ";
					}
					$reactants .= "(".(-1*$rgt->coefficient()).") ".$rgt->modelcompound()->compound()->id().$suffix;
				}
			}
			for (my $j=0;$j < @{$rgts}; $j++) {
				my $rgt = $rgts->[$j];
				if ($rgt->coefficient() > 0) {
					my $suffix = "";
					if ($rgt->modelcompound()->modelcompartment()->compartmentIndex() != 0) {
						$suffix .= "_".$rgt->modelcompound()->modelcompartment()->compartmentIndex();
					}
					$suffix .= "[".$rgt->modelcompound()->modelcompartment()->compartment()->id()."]";
					if (length($products) > 0) {
						$products .= " + ";
					}
					$products .= "(".$rgt->coefficient().") ".$rgt->modelcompound()->compound()->id().$suffix;
				}
			}
			my $equation = $reactants." ".$rxndir." ".$products;
			my $cols = ["abbreviation","deltaG","deltaGErr","equation","id","name","direction","status","direction"];
			my $rxnline = "";
			for (my $j=0; $j < @{$cols}; $j++) {
				my $function = $cols->[$j];
				if ($j > 0) {
					$rxnline .= "\t";
				}
				if ($function eq "direction") {
					$rxnline .= $direction;
				} elsif ($function eq "equation") {
					$rxnline .= $equation;
				} elsif ($function eq "id") {
					$rxnline .= $id;
				} elsif ($function eq "name") {
					$rxnline .= $name;
				} elsif (defined($rxn->reaction()->$function())) {
					$rxnline .= $rxn->reaction()->$function();
				}
			}
			push(@{$BioRxn},$rxnline);
		}
	}
	if (defined($self->parameters()->{"Complete gap filling"}) && $self->parameters()->{"Complete gap filling"} == 1) {
		$mdlcpd = $self->biochemistry()->compounds();
		for (my $i=0; $i < @{$mdlcpd}; $i++) {
			my $cpd = $mdlcpd->[$i];
			if (!defined($cpdhash->{$cpd->id()."_0"})) {
				my $line = "";
				my $cols = ["abbreviation","defaultCharge","deltaG","deltaGErr","formula","id","mass","name"];
				$cpdhash->{$cpd->id()."_0"} = 1;
				for (my $j=0; $j < @{$cols}; $j++) {
					my $function = $cols->[$j];
					if ($j > 0) {
						$line .= "\t";
					}
					if (defined($cpd->$function())) {
						$line .= $cpd->$function();
					}
				}
				push(@{$BioCpd},$line);
			}
		}
		my $mdlrxn = $self->biochemistry()->reactions();
		for (my $i=0; $i < @{$mdlrxn}; $i++) {
			my $rxn = $mdlrxn->[$i];
			if (!defined($rxnhash->{$rxn->id()})) {
				my $line = "";
				$rxnhash->{$rxn->id()} = 1;
				my $reactants = "";
				my $products = "";
				my $rgts = $rxn->reagents();
				for (my $j=0;$j < @{$rgts}; $j++) {
					my $rgt = $rgts->[$j];
					if ($rgt->coefficient() < 0) {
						my $suffix = "[".$rgt->compartment()->id()."]";
						if (length($reactants) > 0) {
							$reactants .= " + ";
						}
						$reactants .= "(".(-1*$rgt->coefficient()).") ".$rgt->compound()->id().$suffix;
					}
				}
				for (my $j=0;$j < @{$rgts}; $j++) {
					my $rgt = $rgts->[$j];
					if ($rgt->coefficient() > 0) {
						my $suffix = "";
						$suffix .= "[".$rgt->compartment()->id()."]";
						if (length($products) > 0) {
							$products .= " + ";
						}
						$products .= "(".$rgt->coefficient().") ".$rgt->compound()->id().$suffix;
					}
				}
				my $direction = $rxn->thermoReversibility();
				if (!defined($direction)) {
					$direction = "=";
				}
				my $rxndir = "<=>";
				if ($direction eq ">") {
					$rxndir = "=>";
				} elsif ($direction eq "<") {
					$rxndir = "<=";
				}
				my $equation = $reactants." ".$rxndir." ".$products;
				my $cols = ["abbreviation","deltaG","deltaGErr","equation","id","name","direction","status","direction"];
				my $rxnline = "";
				for (my $j=0; $j < @{$cols}; $j++) {
					my $function = $cols->[$j];
					if ($j > 0) {
						$rxnline .= "\t";
					}
					if ($function eq "direction") {
						$rxnline .= $direction;
					} elsif ($function eq "equation") {
						$rxnline .= $equation;
					} elsif (defined($rxn->$function())) {
						$rxnline .= $rxn->$function();
					}
				}
				push(@{$BioRxn},$rxnline);
			}
		}
	}
	my $biomasses = $model->biomasses();
	for (my $i=0; $i < @{$biomasses}; $i++) {
		my $bio = $biomasses->[$i];
		push(@{$mdlData},$bio->id().";=>;c;UNIVERSAL");
		my $reactants = "";
		my $products = "";
		my $rgts = $bio->biomasscompounds();
		for (my $j=0;$j < @{$rgts}; $j++) {
			my $rgt = $rgts->[$j];
			if ($rgt->coefficient() < 0) {
				my $suffix = "";
				if ($rgt->modelcompound()->modelcompartment()->compartmentIndex() != 0) {
					$suffix .= "_".$rgt->modelcompound()->modelcompartment()->compartmentIndex();
				}
				$suffix .= "[".$rgt->modelcompound()->modelcompartment()->compartment()->id()."]";
				if (length($reactants) > 0) {
					$reactants .= " + ";
				}
				$reactants .= "(".(-1*$rgt->coefficient()).") ".$rgt->modelcompound()->compound()->id().$suffix;
			}
		}
		for (my $j=0;$j < @{$rgts}; $j++) {
			my $rgt = $rgts->[$j];
			if ($rgt->coefficient() > 0) {
				my $suffix = "";
				if ($rgt->modelcompound()->modelcompartment()->compartmentIndex() != 0) {
					$suffix .= "_".$rgt->modelcompound()->modelcompartment()->compartmentIndex();
				}
				$suffix .= "[".$rgt->modelcompound()->modelcompartment()->compartment()->id()."]";
				if (length($products) > 0) {
					$products .= " + ";
				}
				$products .= "(".$rgt->coefficient().") ".$rgt->modelcompound()->compound()->id().$suffix;
			}
		}
		my $equation = $reactants." => ".$products;
		my $rxnline = $bio->id()."\t0\t0\t".$equation."\t".$bio->id()."\t".$bio->id()."\t>\tOK\t>";
		push(@{$BioRxn},$rxnline);
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Compounds.tbl",$BioCpd);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Reactions.tbl",$BioRxn);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."Model.tbl",$mdlData);
	#Printing additional input files specified in formulation
	my $inputfileHash = $self->inputfiles();
	foreach my $filename (keys(%{$inputfileHash})) {
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory.$filename,$inputfileHash->{$filename});
	}
	#Setting drain max based on media
	my $primMedia = $self->media();
	if ($primMedia->name() eq "Complete") {
		if ($self->defaultMaxDrainFlux() <= 0) {
			$self->defaultMaxDrainFlux($self->defaultMaxFlux());
		}
	}
	my $addnlCpds = $self->additionalCpds();
	if (@{$addnlCpds} > 0) {
		my $newPrimMedia = $primMedia->cloneObject();
		$newPrimMedia->name("TempPrimaryMedia");
		$newPrimMedia->id("TempPrimaryMedia");
		my $mediaCpds = $newPrimMedia->mediacompounds();
		for (my $i=0; $i < @{$addnlCpds}; $i++) {
			my $found = 0;
			for (my $j=0; $j < @{$mediaCpds}; $j++) {
				if ($mediaCpds->[$j]->compound_ref() eq $addnlCpds->[$i]->_reference()) {
					$mediaCpds->[$j]->maxFlux() = 100;
				}
			}
			if ($found == 0) {
				$newPrimMedia->add("mediacompounds",{compound_ref => $addnlCpds->[$i]->_reference()});
			}
		}
		$primMedia = $newPrimMedia;
	}
	#Selecting the solver based on whether the problem is MILP
	my $solver = "GLPK";
	if ($self->fluxUseVariables() == 1 || $self->drainfluxUseVariables() == 1 || $self->findMinimalMedia()) {
		$solver = "SCIP";
	}
	#Setting gene KO
	my $geneKO = "none";
	for (my $i=0; $i < @{$self->geneKOs()}; $i++) {
		my $gene = $self->geneKOs()->[$i];
		if ($i == 0) {
			$geneKO = $gene->id();	
		} else {
			$geneKO .= ";".$gene->id();
		}
	}
	$geneKO =~ s/\|/___/g;
	#Setting reaction KO
	my $rxnKO = "none";
	for (my $i=0; $i < @{$self->reactionKOs()}; $i++) {
		my $rxn = $self->reactionKOs()->[$i];
		if ($i == 0) {
			$rxnKO = $rxn->id();	
		} else {
			$rxnKO .= ";".$rxn->id();
		}
	}
	#Setting exchange species
	my $exchangehash = {
		cpd11416 => {
			c => [-10000,0]
		},
		cpd02701 => {
			c => [-10000,0]
		}
	};
	#Setting the objective
	my $objective = "MAX";
	my $metToOpt = "REACTANTS;bio1";
	my $optMetabolite = 1;
	if ($self->fva() == 1 || $self->comboDeletions() > 0) {
		$optMetabolite = 0;
	}
	if ($self->maximizeObjective() == 0) {
		$objective = "MIN";
		$optMetabolite = 0;
	}
	foreach my $objid (keys(%{$self->compoundflux_objterms()})) {
		my $entity = $model->getObject("modelcompounds",$objid);
		if (defined($entity)) {
			$objective .= ";DRAIN_FLUX;".$objid.";".$entity->modelcompartment()->label().";".$self->compoundflux_objterms()->{$objid};
			$exchangehash->{$objid} = {c => [-10000,0]};
		}
	}
	foreach my $objid (keys(%{$self->reactionflux_objterms()})) {
		my $entity = $model->getObject("modelreactions",$objid);
		if (defined($entity)) {
			$objective .= ";FLUX;".$objid.";".$entity->modelcompartment()->label().";".$self->reactionflux_objterms()->{$objid};
		}
	}
	foreach my $objid (keys(%{$self->biomassflux_objterms()})) {
		my $entity = $model->getObject("biomasses",$objid);
		if (defined($entity)) {
			$objective .= ";FLUX;".$objid.";none;".$self->biomassflux_objterms()->{$objid};
		}
	}
	my $exchange = "";
	foreach my $key (keys(%{$exchangehash})) {
		if (length($exchange) > 0) {
			$exchange .= ";";
		}
		foreach my $comp (keys(%{$exchangehash->{$key}})) {
			$exchange .= $key."[".$comp."]:".$exchangehash->{$key}->{$comp}->[0].":".$exchangehash->{$key}->{$comp}->[1];
		}
	}
	#Setting up uptake limits
	my $uptakeLimits = "none";
	foreach my $atom (keys(%{$self->uptakeLimits()})) {
		if ($uptakeLimits eq "none") {
			$uptakeLimits = $atom.":".$self->uptakeLimits()->{$atom};
		} else {
			$uptakeLimits .= ";".$atom.":".$self->uptakeLimits()->{$atom};
		}
	}
	my $comboDeletions = $self->comboDeletions();
	if ($comboDeletions == 0) {
		$comboDeletions = "none";
	}
	#Creating FBA experiment file
	my $medialist = [$primMedia];
	my $fbaExpFile = $self->setupFBAExperiments($medialist);
	if ($fbaExpFile ne "none") {
		$optMetabolite = 0;
	}
	#Setting parameters
	my $parameters = {
		"perform MFA" => 1,
		"Default min drain flux" => $self->defaultMinDrainFlux(),
		"Default max drain flux" => $self->defaultMaxDrainFlux(),
		"Max flux" => $self->defaultMaxFlux(),
		"Min flux" => -1*$self->defaultMaxFlux(),
		"user bounds filename" => $primMedia->name(),
		"create file on completion" => "FBAComplete.txt",
		"Reactions to knockout" => $rxnKO,
		"Genes to knockout" => $geneKO,
		"output folder" => $self->jobID()."/",
		"use database fields" => 1,
		"MFASolver" => $solver,
		"exchange species" => $exchange,
		"database spec file" => $directory."StringDBFile.txt",
		"Reactions use variables" => $self->fluxUseVariables(),
		"Force use variables for all reactions" => 1,
		"Add use variables for any drain fluxes" => $self->drainfluxUseVariables(),
		"Decompose reversible reactions" => $self->decomposeReversibleFlux(),
		"Decompose reversible drain fluxes" => $self->decomposeReversibleDrainFlux(),
		"Make all reactions reversible in MFA" => $self->allReversible(),
		"Constrain objective to this fraction of the optimal value" => $self->objectiveConstraintFraction(),
		"objective" => $objective,
		"find tight bounds" => $self->fva(),
		"Combinatorial deletions" => $comboDeletions,
		"flux minimization" => $self->fluxMinimization(), 
		"uptake limits" => $uptakeLimits,
		"optimize metabolite production if objective is zero" => $optMetabolite,
		"metabolites to optimize" => $metToOpt,
		"FBA experiment file" => $fbaExpFile,
		"determine minimal required media" => $self->findMinimalMedia(),
		"Recursive MILP solution limit" => $self->numberOfSolutions(),
		"database root output directory" => $self->jobPath()."/",
		"database root input directory" => $self->jobDirectory()."/",
	};
	if (defined($self->prommodel_ref()) && length($self->prommodel_ref()) > 0) {
		my $softConst = $self->PROMKappa();
		my $bounds = $self->promBounds();
		foreach my $key (keys(%{$bounds})) {
			$softConst .= ";".$key.":".$bounds->{$key}->[0].":".$bounds->{$key}->[1];
		}
		$parameters->{"Soft Constraint"} = $softConst;
	}
	if ($solver eq "SCIP") {
		$parameters->{"use simple variable and constraint names"} = 1;
	}
	if ($^O =~ m/^MSWin/) {
		$parameters->{"scip executable"} = "scip.exe";
		$parameters->{"perl directory"} = "C:/Perl/bin/perl.exe";
		$parameters->{"os"} = "windows";
	} else {
		$parameters->{"scip executable"} = "scip";
		$parameters->{"perl directory"} = "/usr/bin/perl";
		$parameters->{"os"} = "linux";
	}
	#Setting thermodynamic constraints
	if ($self->thermodynamicConstraints() eq "none") {
		$parameters->{"Thermodynamic constraints"} = 0;
	} elsif ($self->thermodynamicConstraints() eq "simple") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"simple thermo constraints"} = 1;
	} elsif ($self->thermodynamicConstraints() eq "error") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 1;
		$parameters->{"minimize deltaG error"} = 0;
	} elsif ($self->thermodynamicConstraints() eq "noerror") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 0;
		$parameters->{"minimize deltaG error"} = 0;
	} elsif ($self->thermodynamicConstraints() eq "minerror") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 1;
		$parameters->{"minimize deltaG error"} = 1;
	}
	#Setting overide parameters
	foreach my $param (keys(%{$self->parameters()})) {
		$parameters->{$param} = $self->parameters()->{$param};
	}
	#Printing parameter file
	my $paramData = [];
	foreach my $param (keys(%{$parameters})) {
		push(@{$paramData},$param."|".$parameters->{$param}."|Specialized parameters");
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."SpecializedParameters.txt",$paramData);
	#Printing specialized bounds
	my $mediaData = ["ID\tNAMES\tVARIABLES\tTYPES\tMAX\tMIN\tCOMPARTMENTS"];
	my $cpdbnds = $self->FBACompoundBounds();
	my $rxnbnds = $self->FBAReactionBounds();
	foreach my $media (@{$medialist}) {
		my $userBounds = {};
		my $mediaCpds = $media->mediacompounds();
		for (my $i=0; $i < @{$mediaCpds}; $i++) {
			if (defined($self->parameters()->{"Complete gap filling"}) && $self->parameters()->{"Complete gap filling"} == 1) {
				$userBounds->{$mediaCpds->[$i]->compound()->id()}->{"e"}->{"DRAIN_FLUX"} = {
					max => 10000,
					min => -10000
				};
			} else {
				$userBounds->{$mediaCpds->[$i]->compound()->id()}->{"e"}->{"DRAIN_FLUX"} = {
					max => $mediaCpds->[$i]->maxFlux(),
					min => $mediaCpds->[$i]->minFlux()
				};
			}
		}
		for (my $i=0; $i < @{$cpdbnds}; $i++) {
			if (defined($self->parameters()->{"Complete gap filling"}) && $self->parameters()->{"Complete gap filling"} == 1) {
				$userBounds->{$cpdbnds->[$i]->compound()->id()}->{$cpdbnds->[$i]->modelcompartment()->label()}->{$translation->{$cpdbnds->[$i]->variableType()}} = {
					max => 10000,
					min => -10000
				};
			} else {
				$userBounds->{$cpdbnds->[$i]->compound()->id()}->{$cpdbnds->[$i]->modelcompartment()->label()}->{$translation->{$cpdbnds->[$i]->variableType()}} = {
					max => $cpdbnds->[$i]->upperBound(),
					min => $cpdbnds->[$i]->lowerBound()
				};
			}
		}
		for (my $i=0; $i < @{$rxnbnds}; $i++) {
			if (defined($self->parameters()->{"Complete gap filling"}) && $self->parameters()->{"Complete gap filling"} == 1) {
				$userBounds->{$rxnbnds->[$i]->reaction()->id()}->{$rxnbnds->[$i]->modelcompartment()->label()}->{$translation->{$rxnbnds->[$i]->variableType()}} = {
					max => 10000,
					min => -10000
				};
			} else {
				$userBounds->{$rxnbnds->[$i]->reaction()->id()}->{$rxnbnds->[$i]->modelcompartment()->label()}->{$translation->{$rxnbnds->[$i]->variableType()}} = {
					max => $rxnbnds->[$i]->upperBound(),
					min => $rxnbnds->[$i]->lowerBound()
				};
			}
		}
		my $dataArrays;
		foreach my $var (keys(%{$userBounds})) {
			foreach my $comp (keys(%{$userBounds->{$var}})) {
				foreach my $type (keys(%{$userBounds->{$var}->{$comp}})) {
					push(@{$dataArrays->{var}},$var);
					push(@{$dataArrays->{type}},$type);
					push(@{$dataArrays->{min}},$userBounds->{$var}->{$comp}->{$type}->{min});
					push(@{$dataArrays->{max}},$userBounds->{$var}->{$comp}->{$type}->{max});
					push(@{$dataArrays->{comp}},$comp);
				}
			}
		}
		my $newLine = $media->name()."\t".$media->name()."\t";
		if (defined($dataArrays->{var}) && @{$dataArrays->{var}} > 0) {
			$newLine .= 
				join("|",@{$dataArrays->{var}})."\t".
				join("|",@{$dataArrays->{type}})."\t".
				join("|",@{$dataArrays->{max}})."\t".
				join("|",@{$dataArrays->{min}})."\t".
				join("|",@{$dataArrays->{comp}});
		} else {
			$newLine .= "\t\t\t\t";
		}
		push(@{$mediaData},$newLine);
	}
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."media.tbl",$mediaData);
	#Set StringDBFile.txt
	my $mfatkdir = $self->mfatoolkitDirectory();
	my $stringdb = [
		"Name\tID attribute\tType\tPath\tFilename\tDelimiter\tItem delimiter\tIndexed columns",
		"compound\tid\tSINGLEFILE\t\t".$directory."Compounds.tbl\tTAB\tSC\tid",
		"reaction\tid\tSINGLEFILE\t".$directory."reaction/\t".$directory."Reactions.tbl\tTAB\t|\tid",
		"cue\tNAME\tSINGLEFILE\t\t".$mfatkdir."../etc/MFAToolkit/cueTable.txt\tTAB\t|\tNAME",
		"media\tID\tSINGLEFILE\t".$directory."media/\t".$directory."media.tbl\tTAB\t|\tID;NAMES"		
	];
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."StringDBFile.txt",$stringdb);
	#Write shell script
	my $exec = [
		$self->mfatoolkitBinary().' resetparameter "MFA input directory" "'.$directory.'ReactionDB/" parameterfile "'.$directory.'SpecializedParameters.txt" LoadCentralSystem "'.$directory.'Model.tbl" > "'.$directory.'log.txt"'
	];
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($directory."runMFAToolkit.sh",$exec);
	chmod 0775,$directory."runMFAToolkit.sh";
	$self->command($self->mfatoolkitBinary().' parameterfile "'.$directory.'SpecializedParameters.txt" LoadCentralSystem "'.$directory.'Model.tbl" > "'.$directory.'log.txt"');
}

=head3 setupFBAExperiments

Definition:
	string:FBA experiment filename = setupFBAExperiments());
Description:
	Converts phenotype simulation specs into an FBA experiment file for the MFAToolkit

=cut

sub setupFBAExperiments {
	my ($self,$medialist) = @_;
	my $fbaExpFile = "none";
	if (defined($self->phenotypeset_ref()) && defined($self->phenotypeset())) {
		my $phenoset = $self->phenotypeset();
		$fbaExpFile = "FBAExperiment.txt";
		my $phenoData = ["Label\tKO\tMedia"];
		my $mediaHash = {};
		my $tempMediaIndex = 1;
		my $phenos = $phenoset->phenotypes();
		for (my $i=0; $i < @{$phenos}; $i++) {
			my $pheno = $phenos->[$i];
			my $phenoko = "none";
			my $addnlCpds = $pheno->additionalcompound_refs();
			my $media = $pheno->media()->name();
			if (@{$addnlCpds} > 0) {
				if (!defined($mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))})) {
					$mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))} = $self->createTemporaryMedia({
						name => "Temp".$tempMediaIndex,
						media => $pheno->media(),
						additionalCpd => $pheno->additionalcompounds()
					});
					$tempMediaIndex++;
				}
				$media = $mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))}->name();
			} else {
				$mediaHash->{$media} = $pheno->media();
			}
			for (my $j=0; $j < @{$pheno->genekos()}; $j++) {
				if ($phenoko eq "none") {
					$phenoko = $1;
				} else {
					$phenoko .= ";".$1;
				}
			}
			$phenoko =~ s/\|/___/g;
			push(@{$phenoData},$pheno->id()."\t".$phenoko."\t".$media);
		}
		foreach my $key (keys(%{$mediaHash})) {
			push(@{$medialist},$mediaHash->{$key});
		}
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($self->jobDirectory()."/".$fbaExpFile,$phenoData);
	}
	return $fbaExpFile;
}

=head3 createTemporaryMedia

Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Media = createTemporaryMedia({
		name => "Temp".$tempMediaIndex,
		media => $fbaSims->[$i]->media(),
		additionalCpd => $fbaSims->[$i]->additionalCpds()
	});
Description:
	Creates a temporary media conditions with the specified base media plus the specified additional compounds

=cut

sub createTemporaryMedia {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["name","media","additionalCpd"],{}, @_);
	my $newMedia = Bio::KBase::ObjectAPI::KBaseBiochem::Media->new({
		isDefined => 1,
		isMinimal => 0,
		id => $args->{name},
		name => $args->{name},
		type => "temporary"
	});
	my $cpds = $args->{media}->mediacompounds();
	my $cpdHash = {};
	foreach my $cpd (@{$cpds}) {
		$cpdHash->{$cpd->compound_ref()} = {
			compound_ref => $cpd->compound_ref(),
			concentration => $cpd->concentration(),
			maxFlux => $cpd->maxFlux(),
			minFlux => $cpd->minFlux(),
		};
	}
	foreach my $cpd (@{$args->{additionalCpd}}) {
		$cpdHash->{$cpd->_reference()} = {
			compound_ref => $cpd->_reference(),
			concentration => 0.001,
			maxFlux => 100,
			minFlux => -100,
		};
	}
	foreach my $cpd (keys(%{$cpdHash})) {
		$newMedia->add("mediacompounds",$cpdHash->{$cpd});	
	}
	return $newMedia;
}

=head3 export

Definition:
	string = Bio::KBase::ObjectAPI::KBaseFBA::FBA->export({
		format => readable/html/json
	});
Description:
	Exports media data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
}

=head3 htmlComponents

Definition:
	string = Bio::KBase::ObjectAPI::KBaseFBA::FBA->htmlComponents();
Description:
	Generates html view of FBA result

=cut

sub htmlComponents {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([],{}, @_);
	my $data = $self->_createReadableData();
	my $output = {
		title => "FBA Viewer",
		tablist => [],
		tabs => {
			main => {
				content => "",
				name => "Overview"
			}
		}
	};
	$output->{tabs}->{main}->{content} .= "<table>\n";
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		$output->{tabs}->{main}->{content} .= "<tr><th>".$data->{attributes}->{headings}->[$i]."</th><td style='font-size:16px;border: 1px solid black;'>".$data->{attributes}->{data}->[0]->[$i]."</td></tr>\n";
	}
	if (defined($self->objectiveValue())) {
		$output->{tabs}->{main}->{content} .= "<tr><th>Objective value</th><td style='font-size:16px;border: 1px solid black;'>".$self->objectiveValue()."</td></tr>\n";
	}
	$output->{tabs}->{main}->{content} .= "</table>\n";
	my $index = 2;
	my $tab = "tab-".$index;
	my $headingsOne = ["Media compound","Compound name","Concentration","Min uptake","Max uptake"];
        my $dataOne = [];
	if (@{$self->media()->mediacompounds()} > 0) {
		$index++;
		foreach my $medcpd (@{$self->media()->mediacompounds()}) {
                        push(@$dataOne, [
				$medcpd->compound()->id(),
				$medcpd->compound()->name(),
				$medcpd->concentration(),
				$medcpd->minFlux(),
				$medcpd->maxFlux()
                        ]);
		}
		$output->{tabs}->{$tab} = {
                        content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
			name => "Media"
		};
		push(@{$output->{tablist}},$tab);
	}
	if (@{$self->FBAReactionBounds()} > 0 || @{$self->FBACompoundBounds()} > 0) {
		$tab = "tab-".$index;
		$index++;
		$headingsOne = ["Variable ID","Definition","Type","Upper bound","Lower bound"];
                $dataOne = [];
		foreach my $bound (@{$self->FBACompoundBounds()}) {
                        push(@$dataOne, [
                                $bound->modelCompound()->id(),
                                $bound->modelCompound()->name(),
                                $bound->variableType(),
                                $bound->upperBound(),
                                $bound->lowerBound()
                        ]);
		}
		foreach my $bound (@{$self->FBAReactionBounds()}) {
                        push(@$dataOne, [
				$bound->modelReaction()->id(),
				$bound->modelReaction()->definition(),
				$bound->variableType(),
				$bound->upperBound(),
				$bound->lowerBound()
                        ]);
		}
		$output->{tabs}->{$tab} = {
                        content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
			name => "Bounds"
		};
		push(@{$output->{tablist}},$tab);
	}
	if (@{$self->FBAConstraints()} > 0) {
		$tab = "tab-".$index;
		$index++;
		$headingsOne = ["Name","Constraint"];
                $dataOne = [];
		foreach my $const (@{$self->FBAConstraints()}) {
                        push(@$dataOne, [ $const->name(), $const->readableString() ]);
		}
		$output->{tabs}->{$tab} = {
                        content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
			name => "Constraints"
		};
		push(@{$output->{tablist}},$tab);
	}
	#Retrieving result
	if (defined($self->objectiveValue())) {
		$tab = "tab-".$index;
		$index++;
		$headingsOne = ["Reaction ID","Definition","Variable","Value","Lower bound","Upper bound","Min","Max","Class"];
                $dataOne = [];
		foreach my $rxnflux (@{$self->FBAReactionVariables()}) {
                        push(@$dataOne, [
				$rxnflux->modelreaction()->id(),
				$rxnflux->modelreaction()->definition(),
				$rxnflux->variableType(),
				$rxnflux->value(),
				$rxnflux->lowerBound(),
				$rxnflux->upperBound(),
				$rxnflux->min(),
				$rxnflux->max(),
				$rxnflux->class()
                        ]);
		}
		foreach my $rxnflux (@{$self->FBABiomassVariables()}) {
                        push(@$dataOne, [
				$rxnflux->biomass()->id(),
				$rxnflux->biomass()->definition(),
				$rxnflux->variableType(),
				$rxnflux->value(),
				$rxnflux->lowerBound(),
				$rxnflux->upperBound(),
				$rxnflux->min(),
				$rxnflux->max(),
				$rxnflux->class()
                        ]);
		}
		$output->{tabs}->{$tab} = {
                        content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
			name => "Reaction fluxes"
		};
		push(@{$output->{tablist}},$tab);
		$tab = "tab-".$index;
		$index++;
		$headingsOne = ["Compound ID","Name","Variable","Value","Lower bound","Upper bound","Min","Max","Class"];
                $dataOne = [];
		foreach my $cpdflux (@{$self->FBACompoundVariables()}) {
                        push(@$dataOne, [
				$cpdflux->modelcompound()->id(),
				$cpdflux->modelcompound()->name(),
				$cpdflux->variableType(),
				$cpdflux->value(),
				$cpdflux->lowerBound(),
				$cpdflux->upperBound(),
				$cpdflux->min(),
				$cpdflux->max(),
				$cpdflux->class()
                        ]);
		}
		$output->{tabs}->{$tab} = {
                        content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
			name => "Compound fluxes"
		};
		push(@{$output->{tablist}},$tab);
		if (@{$self->FBAPromResults()} > 0) {
			$tab = "tab-".$index;
			$index++;
			$headingsOne = ["Objective fraction","Alpha","Beta"];
                        $dataOne = [];
			foreach my $promres (@{$self->FBAPromResults()}) {
            	push(@{$dataOne},[
            		$promres->objectFraction(),
            		$promres->alpha(),
            		$promres->beta()
            	]);    
			}
			$output->{tabs}->{$tab} = {
                                content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
				name => "PROM results"
			};
			push(@{$output->{tablist}},$tab);
		}
		if (@{$self->FBADeletionResults()} > 0) {
			$tab = "tab-".$index;
			$index++;
			$headingsOne = ["Gene KOs","Growth fraction"];
                        $dataOne = [];
			foreach my $delres (@{$self->FBADeletionResults()}) {
				my $genes = "";
				for (my $i=0; $i < @{$delres->genekos()}; $i++) {
					if (length($genes) > 0) {
						$genes .= ";";
					}
					$genes .= $delres->genekos()->[$i]->id();
				}
                                push(@$dataOne, [
					$genes,
					$delres->growthFraction()
                                ]);
			}
			$output->{tabs}->{$tab} = {
                                content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
				name => "Deletion results"
			};
			push(@{$output->{tablist}},$tab);
		}
		if (@{$self->FBAMinimalMediaResults()} > 0) {
			$tab = "tab-".$index;
			$index++;
			$headingsOne = ["Media index","Essential nutrient","Compound ID","Name"];
                        $dataOne = [];
			my $mediaIndex = 0;
			foreach my $minmed (@{$self->FBAMinimalMediaResults()}) {
				foreach my $minmedcpd (@{$minmed->essentialNutrients()}) {
                                        push(@$dataOne, [
						$mediaIndex,
						"Yes",
						$minmedcpd->id(),
						$minmedcpd->name()
                                        ]);
				}
				foreach my $minmedcpd (@{$minmed->optionalNutrients()}) {
                                        push(@$dataOne, [
						$mediaIndex,
						"No",
						$minmedcpd->id(),
						$minmedcpd->name()
                                        ]);
				}
				$mediaIndex++;
			}
			$output->{tabs}->{$tab} = {
                                content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
				name => "Minimal media"
			};
			push(@{$output->{tablist}},$tab);
		}
		if (@{$self->FBAMetaboliteProductionResults()} > 0) {
			$tab = "tab-".$index;
			$index++;
			$headingsOne = ["Compound ID","Name","Maximum production"];
                        $dataOne = [];
			foreach my $metprod (@{$self->FBAMetaboliteProductionResults()}) {
                                push(@$dataOne, [
					$metprod->modelcompound()->id(),
					$metprod->modelcompound()->name(),
					$metprod->maximumProduction()
                                ]);
			}
			$output->{tabs}->{$tab} = {
                                content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
				name => "Compound production"
			};
			push(@{$output->{tablist}},$tab);
		}
	}
	return $output;
}

=head3 buildFromOptSolution

Definition:
	ModelSEED::MS::FBAResults = ModelSEED::MS::FBAResults->runFBA();
Description:
	Runs the FBA study described by the fomulation and returns a typed object with the results

=cut

sub buildFromOptSolution {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["LinOptSolution"],{}, @_);
	my $solvars = $args->{LinOptSolution}->solutionvariables();
	for (my $i=0; $i < @{$solvars}; $i++) {
		my $var = $solvars->[$i];
		my $type = $var->variable()->type();
		if ($type eq "flux" || $type eq "forflux" || $type eq "revflux" || $type eq "fluxuse" || $type eq "forfluxuse" || $type eq "revfluxuse") {
			$self->integrateReactionFluxRawData($var);
		} elsif ($type eq "biomassflux") {
			$self->add("FBABiomassVariables",{
				biomass_ref => $var->variable()->entity_ref(),
				variableType => $type,
				lowerBound => $var->variable()->lowerBound(),
				upperBound => $var->variable()->upperBound(),
				min => $var->min(),
				max => $var->max(),
				value => $var->value()
			});
		} elsif ($type eq "drainflux" || $type eq "fordrainflux" || $type eq "revdrainflux" || $type eq "drainfluxuse" || $type eq "fordrainfluxuse" || $type eq "revdrainfluxuse") {
			$self->integrateCompoundFluxRawData($var);
		}
	}	
}

=head3 integrateReactionFluxRawData

Definition:
	void ModelSEED::MS::FBAResults->integrateReactionFluxRawData();
Description:
	Translates a raw flux or flux use variable into a reaction variable with decomposed reversible reactions recombined

=cut

sub integrateReactionFluxRawData {
	my ($self,$solVar) = @_;
	my $type = "flux";
	my $max = 0;
	my $min = 0;
	my $var = $solVar->variable();
	if ($var->type() =~ m/use$/) {
		$max = 1;
		$min = -1;
		$type = "fluxuse";	
	}
	my $fbavar = $self->queryObject("FBAReactionVariables",{
		modelreaction_ref => $var->entity_ref(),
		variableType => $type
	});
	if (!defined($fbavar)) {
		$fbavar = $self->add("FBAReactionVariables",{
			modelreaction_ref => $var->entity_ref(),
			variableType => $type,
			lowerBound => $min,
			upperBound => $max,
			min => $min,
			max => $max,
			value => 0
		});
	}
	if ($var->type() eq $type) {
		$fbavar->upperBound($var->upperBound());
		$fbavar->lowerBound($var->lowerBound());
		$fbavar->max($solVar->max());
		$fbavar->min($solVar->min());
		$fbavar->value($solVar->value());
	} elsif ($var->type() eq "for".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->upperBound($var->upperBound());	
		}
		if ($var->lowerBound() > 0) {
			$fbavar->lowerBound($var->lowerBound());
		}
		if ($solVar->max() > 0) {
			$fbavar->max($solVar->max());
		}
		if ($solVar->min() > 0) {
			$fbavar->min($solVar->min());
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() + $solVar->value());
		}
	} elsif ($var->type() eq "rev".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->lowerBound((-1*$var->upperBound()));
		}
		if ($var->lowerBound() > 0) {
			$fbavar->upperBound((-1*$var->lowerBound()));
		}
		if ($solVar->max() > 0) {
			$fbavar->min((-1*$solVar->max()));
		}
		if ($solVar->min() > 0) {
			$fbavar->max((-1*$solVar->min()));
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() - $solVar->value());
		}
	}
}

=head3 integrateCompoundFluxRawData

Definition:
	void ModelSEED::MS::FBAResults->integrateCompoundFluxRawData();
Description:
	Translates a raw flux or flux use variable into a compound variable with decomposed reversible reactions recombined

=cut

sub integrateCompoundFluxRawData {
	my ($self,$solVar) = @_;
	my $var = $solVar->variable();
	my $type = "drainflux";
	my $max = 0;
	my $min = 0;
	if ($var->type() =~ m/use$/) {
		$max = 1;
		$min = -1;
		$type = "drainfluxuse";	
	}
	my $fbavar = $self->queryObject("FBACompoundVariables",{
		modelcompound_ref => $var->entity_ref(),
		variableType => $type
	});
	if (!defined($fbavar)) {
		$fbavar = $self->add("FBACompoundVariables",{
			modelcompound_ref => $var->entity_ref(),
			variableType => $type,
			lowerBound => $min,
			upperBound => $max,
			min => $min,
			max => $max,
			value => 0
		});
	}
	if ($var->type() eq $type) {
		$fbavar->upperBound($var->upperBound());
		$fbavar->lowerBound($var->lowerBound());
		$fbavar->max($solVar->max());
		$fbavar->min($solVar->min());
		$fbavar->value($solVar->value());
	} elsif ($var->type() eq "for".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->upperBound($var->upperBound());	
		}
		if ($var->lowerBound() > 0) {
			$fbavar->lowerBound($var->lowerBound());
		}
		if ($solVar->max() > 0) {
			$fbavar->max($solVar->max());
		}
		if ($solVar->min() > 0) {
			$fbavar->min($solVar->min());
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() + $solVar->value());
		}
	} elsif ($var->type() eq "rev".$type) {
		if ($var->upperBound() > 0) {
			$fbavar->lowerBound((-1*$var->upperBound()));
		}
		if ($var->lowerBound() > 0) {
			$fbavar->upperBound((-1*$var->lowerBound()));
		}
		if ($solVar->max() > 0) {
			$fbavar->min((-1*$solVar->max()));	
		}
		if ($solVar->min() > 0) {
			$fbavar->max((-1*$solVar->min()));
		}
		if ($solVar->value() > 0) {
			$fbavar->value($fbavar->value() - $solVar->value());
		}
	}
}

=head3 loadMFAToolkitResults
Definition:
	void ModelSEED::MS::FBAResult->loadMFAToolkitResults();
Description:
	Loads problem result data from job directory

=cut

sub loadMFAToolkitResults {
	my ($self) = @_;
	$self->parseProblemReport();
	$self->parseFluxFiles();
	$self->parseMetaboliteProduction();
	$self->parseFBAPhenotypeOutput();
	$self->parseMinimalMediaResults();
	$self->parseCombinatorialDeletionResults();
	$self->parseFVAResults();
	$self->parsePROMResult();
	$self->parseOutputFiles();
}

=head3 parseFluxFiles
Definition:
	void ModelSEED::MS::Model->parseFluxFiles();
Description:
	Parses files with flux data

=cut

sub parseFluxFiles {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/SolutionCompoundData.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/SolutionCompoundData.txt",";");
		my $drainCompartmentColumns = {};
		my $compoundColumn = -1;
		for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
			if ($tbl->{headings}->[$i] eq "Compound") {
				$compoundColumn = $i;
			} elsif ($tbl->{headings}->[$i] =~ m/Drain\[([a-zA-Z0-9]+)\]/) {
				$drainCompartmentColumns->{$1} = $i;
			}
		}
		my $mediaCpdHash = {};
		my $mediaCpds = $self->media()->mediacompounds();
		for (my $i=0; $i < @{$mediaCpds}; $i++) {
			$mediaCpdHash->{$mediaCpds->[$i]->compound()->id()} = 1;
		}
		if ($compoundColumn != -1) {
			foreach my $row (@{$tbl->{data}}) {
				foreach my $comp (keys(%{$drainCompartmentColumns})) {
					if ($row->[$drainCompartmentColumns->{$comp}] ne "none") {
						my $id = $row->[$compoundColumn]."_".$comp."0";
						if ($row->[$compoundColumn] =~ m/(.+)_(\d+)/) {
							my $cpd = $1;
							my $index = $2;
							if ($index > 0) {
								$id = $cpd."_".$comp.$index;
							}
						}
						my $mdlcpd = $self->fbamodel()->getObject("modelcompounds",$id);
						if (defined($mdlcpd)) {
							my $value = $row->[$drainCompartmentColumns->{$comp}];
							if (abs($value) < 0.00000001) {
								$value = 0;
							}
							my $lower = $self->defaultMinDrainFlux();
							my $upper = $self->defaultMaxDrainFlux();
							if ($comp eq "e" && defined($mediaCpdHash->{$mdlcpd->compound()->id()})) {
								$upper = $self->defaultMaxFlux();
							}
							$self->add("FBACompoundVariables",{
								modelcompound_ref => $mdlcpd->_reference(),
								variableType => "drainflux",
								value => $value,
								lowerBound => $lower,
								upperBound => $upper,
								min => $lower,
								max => $upper,
								class => "unknown"
							});
						}
					}
				}
			}
		}
	}
	if (-e $directory."/MFAOutput/SolutionReactionData.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/SolutionReactionData.txt",";");
		my $fluxCompartmentColumns = {};
		my $reactionColumn = -1;
		for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
			if ($tbl->{headings}->[$i] eq "Reaction") {
				$reactionColumn = $i;
			} elsif ($tbl->{headings}->[$i] =~ m/Flux\[([a-zA-Z0-9]+)\]/) {
				$fluxCompartmentColumns->{$1} = $i;
			}
		}
		if ($reactionColumn != -1) {
			foreach my $row (@{$tbl->{data}}) {
				foreach my $comp (keys(%{$fluxCompartmentColumns})) {
					if ($row->[$fluxCompartmentColumns->{$comp}] ne "none") {
						my $id = $row->[$reactionColumn]."_".$comp."0";
						if ($row->[$reactionColumn] =~ m/(.+)_(\d+)/) {
							my $rxn = $1;
							my $index = $2;
							if ($index > 0) {
								$id = $rxn."_".$comp.$index;
							}
						}
						my $mdlrxn = $self->fbamodel()->getObject("modelreactions",$id);
						if (defined($mdlrxn)) {
							my $value = $row->[$fluxCompartmentColumns->{$comp}];
							if (abs($value) < 0.00000001) {
								$value = 0;
							}
							my $lower = -1*$self->defaultMaxFlux();
							my $upper = $self->defaultMaxFlux();
							if ($mdlrxn->direction() eq "<") {
								$upper = 0;
							} elsif ($mdlrxn->direction() eq ">") {
								$lower = 0;
							}
							$self->add("FBAReactionVariables",{
								modelreaction_ref => $mdlrxn->_reference(),
								variableType => "flux",
								value => $value,
								lowerBound => $lower,
								upperBound => $upper,
								min => $lower,
								max => $upper,
								class => "unknown"
							});
						}
					}
				}
			}
		}
	}
}

=head3 parseFBAPhenotypeOutput
Definition:
	void ModelSEED::MS::Model->parseFBAPhenotypeOutput();
Description:
	Parses output file generated by FBAPhenotypeSimulation

=cut

sub parseFBAPhenotypeOutput {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/FBAExperimentOutput.txt") {
		#Loading file results into a hash
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/FBAExperimentOutput.txt","\t");
		if (!defined($tbl->{data}->[0]->[5])) {
			return Bio::KBase::ObjectAPI::utilities::ERROR("output file did not contain necessary data");
		}
		my $phenoOutputHash;
		foreach my $row (@{$tbl->{data}}) {
			if (defined($row->[5])) {
				my $fraction = 0;
				if ($row->[5] < 1e-7) {
					$row->[5] = 0;	
				}
				if ($row->[4] < 1e-7) {
					$row->[4] = 0;	
				} else {
					$fraction = $row->[5]/$row->[4];	
				}
				$phenoOutputHash->{$row->[0]} = {
					simulatedGrowth => $row->[5],
					wildtype => $row->[4],
					simulatedGrowthFraction => $fraction,
					noGrowthCompounds => [],
					dependantReactions => [],
					dependantGenes => [],
					fluxes => {},
					class => "UN",
					fbaPhenotypeSimulation_ref => $row->[0]
				};		
				if (defined($row->[6]) && length($row->[6]) > 0) {
					chomp($row->[6]);
					$phenoOutputHash->{$row->[0]}->{noGrowthCompounds} = [split(/;/,$row->[6])];
				}
				if (defined($row->[7]) && length($row->[7]) > 0) {
					$phenoOutputHash->{$row->[0]}->{dependantReactions} = [split(/;/,$row->[7])];
				}
				if (defined($row->[8]) && length($row->[8]) > 0) {
					$phenoOutputHash->{$row->[0]}->{dependantReactions} = [split(/;/,$row->[8])];
				}
				if (defined($row->[9]) && length($row->[9]) > 0) {
					my @fluxList = split(/;/,$row->[9]);
					for (my $j=0; $j < @fluxList; $j++) {
						my @temp = split(/:/,$fluxList[$j]);
						$phenoOutputHash->{$row->[0]}->{fluxes}->{$temp[0]} = $temp[1];
					}
				}
			}
		}
		#Scanning through all phenotype data in FBAFormulation and creating corresponding phenotype result objects
		my $phenos = $self->FBAPhenotypeSimulations();
		for (my $i=0; $i < @{$phenos}; $i++) {
			my $pheno = $phenos->[$i];
			if (defined($phenoOutputHash->{$pheno->_reference()})) {
				if (defined($pheno->observedGrowthFraction())) {
					if ($pheno->observedGrowthFraction() > 0.0001) {
						if ($phenoOutputHash->{$pheno->_reference()}->{simulatedGrowthFraction} > 0) {
							$phenoOutputHash->{$pheno->_reference()}->{class} = "CP";
						} else {
							$phenoOutputHash->{$pheno->_reference()}->{class} = "FN";
						}
					} else {
						if ($phenoOutputHash->{$pheno->_reference()}->{simulatedGrowthFraction} > 0) {
							$phenoOutputHash->{$pheno->_reference()}->{class} = "FP";
						} else {
							$phenoOutputHash->{$pheno->_reference()}->{class} = "CN";
						}
					}
				}
				$self->add("FBAPhenotypeSimultationResults",$phenoOutputHash->{$pheno->_reference()});	
			}
		}
		return 1;
	}
	return 0;
}

=head3 parseMetaboliteProduction
Definition:
	void ModelSEED::MS::Model->parseMetaboliteProduction();
Description:
	Parses metabolite production file

=cut

sub parseMetaboliteProduction {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/MetaboliteProduction.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/MetaboliteProduction.txt",";");
		foreach my $row (@{$tbl->{data}}) {
			if (defined($row->[1])) {
				my $id = $row->[0]."_c0";
				if ($row->[0] =~ m/(.+)_(\d+)/) {
					my $cpd = $1;
					my $index = $2;
					if ($index > 0) {
						$id = $cpd."_c".$index;
					}
				}
				my $cpd = $self->fbamodel()->getObject("modelcompounds",$id);
				if (defined($cpd)) {
					$self->add("FBAMetaboliteProductionResults",{
						modelcompound_ref => $cpd->_reference(),
						maximumProduction => -1*$row->[1]
					});
				}
			}
		}
		return 1;
	}
	return 0;
}

=head3 parseProblemReport
Definition:
	void ModelSEED::MS::Model->parseProblemReport();
Description:
	Parses problem report

=cut

sub parseProblemReport {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/ProblemReport.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/ProblemReport.txt",";");
		my $column;
		for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
			if ($tbl->{headings}->[$i] eq "Objective") {
				$column = $i;
				last;
			}
		}
		if (defined($tbl->{data}->[0]) && defined($tbl->{data}->[0]->[$column])) {
			$self->objectiveValue($tbl->{data}->[0]->[$column]);
		}
		return 1;
	}
	return 0;
}

=head3 parseMinimalMediaResults
Definition:
	void ModelSEED::MS::Model->parseMinimalMediaResults();
Description:
	Parses minimal media result file

=cut

sub parseMinimalMediaResults {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/MinimalMediaResults.txt") {
		my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/MFAOutput/MinimalMediaResults.txt");
		my $essIDs = [split(/;/,$data->[1])];
		my $essCpds;
		my $essuuids;
		for (my $i=0; $i < @{$essIDs};$i++) {
			my $cpd = $self->biochemistry()->getObject("compounds",$essIDs->[$i]);
			if (defined($cpd)) {
				push(@{$essCpds},$cpd);
				push(@{$essuuids},$cpd->_reference());	
			}
		}
		my $count = 1;
		for (my $i=3; $i < @{$data}; $i++) {
			if ($data->[$i] !~ m/^Dead/) {
				my $optIDs = [split(/;/,$data->[$i])];
				my $optCpds;
				my $optuuids;
				for (my $j=0; $j < @{$optIDs};$j++) {
					my $cpd = $self->biochemistry()->getObject("compounds",$optIDs->[$j]);
					if (defined($cpd)) {
						push(@{$optCpds},$cpd);
						push(@{$optuuids},$cpd->_reference());
					}
				}
				$self->add("FBAMinimalMediaResults",{
					essentialNutrient_refs => $essuuids,
					optionalNutrient_refs => $optuuids
				});
				$count++;
			} else {
				last;	
			}
		}
	}
}

=head3 parseCombinatorialDeletionResults
Definition:
	void ModelSEED::MS::Model->parseCombinatorialDeletionResults();
Description:
	Parses combinatorial deletion results

=cut

sub parseCombinatorialDeletionResults {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/CombinationKO.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/CombinationKO.txt","\t");
		foreach my $row (@{$tbl->{data}}) {
			if (defined($row->[1])) {
				my $array = [split(/;/,$row->[0])];
				my $geneArray = [];
				for (my $i=0; $i < @{$array}; $i++) {
					my $geneID = $array->[$i];
					$geneID =~ s/___/|/;
					my $gene = $self->genome()->getObject("features",$geneID);
					if (defined($gene)) {
						push(@{$geneArray},$gene->_reference());	
					}
				}
				if (@{$geneArray} > 0) {
					$self->add("FBADeletionResults",{
						feature_refs => $geneArray,
						growthFraction => $row->[1]
					});
				}
			}
		}
		return 1;
	}
	return 0;
}

=head3 parseFVAResults
Definition:
	void ModelSEED::MS::Model->parseFVAResults();
Description:
	Parses FVA results

=cut

sub parseFVAResults {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/MFAOutput/TightBoundsReactionData.txt" && -e $directory."/MFAOutput/TightBoundsCompoundData.txt") {
		my $tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/TightBoundsReactionData.txt",";",1);
		if (defined($tbl->{headings}) && defined($tbl->{data})) {
			my $idColumn = -1;
			my $vartrans = {
				FLUX => ["flux",-1,-1],
				DELTAGG_ENERGY => ["deltag",-1,-1],
				REACTION_DELTAG_ERROR => ["deltagerr",-1,-1]
			};
			my $deadRxn = {};
			if (-e $directory."/DeadReactions.txt") {
				my $inputArray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/DeadReactions.txt","");
				if (defined($inputArray)) {
					for (my $i=0; $i < @{$inputArray}; $i++) {
						$deadRxn->{$inputArray->[$i]} = 1;
					}
				}
			}
			for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
				if ($tbl->{headings}->[$i] eq "DATABASE ID") {
					$idColumn = $i;
				} else {
					foreach my $vartype (keys(%{$vartrans})) {
						if ($tbl->{headings}->[$i] eq "Max ".$vartype) {
							$vartrans->{$vartype}->[2] = $i;
							last;
						} elsif ($tbl->{headings}->[$i] eq "Min ".$vartype) {
							$vartrans->{$vartype}->[1] = $i;
							last;
						}
					}
				}
			}
			if ($idColumn >= 0) {
				for (my $i=0; $i < @{$tbl->{data}}; $i++) {
					my $row = $tbl->{data}->[$i];
					if (defined($row->[$idColumn])) {
						my $comp = "c";
						my $id = $row->[$idColumn]."_".$comp."0";
						if ($row->[$idColumn] =~ m/(.+)_(\d+)/) {
							my $rxn = $1;
							my $index = $2;
							if ($index > 0) {
								$id = $rxn."_".$comp.$index;
							}
						}
						my $mdlrxn = $self->fbamodel()->getObject("modelreactions",$id);
						if (defined($mdlrxn)) {
							foreach my $vartype (keys(%{$vartrans})) {
								if ($vartrans->{$vartype}->[1] != -1 && $vartrans->{$vartype}->[2] != -1) {
									my $min = $row->[$vartrans->{$vartype}->[1]];
									my $max = $row->[$vartrans->{$vartype}->[2]];
									if (abs($min) < 0.0000001) {
										$min = 0;	
									}
									if (abs($max) < 0.0000001) {
										$max = 0;	
									}
									my $fbaRxnVar = $self->queryObject("FBAReactionVariables",{
										modelreaction_ref => $mdlrxn->_reference(),
										variableType => $vartrans->{$vartype}->[0],
									});
									if (!defined($fbaRxnVar)) {
										$fbaRxnVar = $self->add("FBAReactionVariables",{
											modelreaction_ref => $mdlrxn->_reference(),
											variableType => $vartrans->{$vartype}->[0]
										});	
									}
									$fbaRxnVar->min($min);
									$fbaRxnVar->max($max);
									if (defined($deadRxn->{$id})) {
										$fbaRxnVar->class("Dead");
									} elsif ($fbaRxnVar->min() > 0) {
										$fbaRxnVar->class("Positive");
									} elsif ($fbaRxnVar->max() < 0) {
										$fbaRxnVar->class("Negative");
									} elsif ($fbaRxnVar->min() == 0 && $fbaRxnVar->max() > 0) {
										$fbaRxnVar->class("Positive variable");
									} elsif ($fbaRxnVar->max() == 0 && $fbaRxnVar->min() < 0) {
										$fbaRxnVar->class("Negative variable");
									} elsif ($fbaRxnVar->max() == 0 && $fbaRxnVar->min() == 0) {
										$fbaRxnVar->class("Blocked");
									} else {
										$fbaRxnVar->class("Variable");
									}
								}
							}
						}
					}
				}
			}
		}
		$tbl = Bio::KBase::ObjectAPI::utilities::LOADTABLE($directory."/MFAOutput/TightBoundsCompoundData.txt",";",1);
		if (defined($tbl->{headings}) && defined($tbl->{data})) {
			my $idColumn = -1;
			my $compColumn = -1;
			my $vartrans = {
				DRAIN_FLUX => ["drainflux",-1,-1],
				LOG_CONC => ["conc",-1,-1],
				DELTAGF_ERROR => ["deltagferr",-1,-1],
				POTENTIAL => ["potential",-1,-1]
			};
			my $deadCpd = {};
			my $deadendCpd = {};
			if (-e $directory."/DeadMetabolites.txt") {
				my $inputArray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/DeadMetabolites.txt","");
				if (defined($inputArray)) {
					for (my $i=0; $i < @{$inputArray}; $i++) {
						$deadCpd->{$inputArray->[$i]} = 1;
					}
				}
			}
			if (-e $directory."/DeadEndMetabolites.txt") {
				my $inputArray = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/DeadEndMetabolites.txt","");
				if (defined($inputArray)) {
					for (my $i=0; $i < @{$inputArray}; $i++) {
						$deadendCpd->{$inputArray->[$i]} = 1;
					}
				}
			}
			for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
				if ($tbl->{headings}->[$i] eq "DATABASE ID") {
					$idColumn = $i;
				} elsif ($tbl->{headings}->[$i] eq "COMPARTMENT") {
					$compColumn = $i;
				} else {
					foreach my $vartype (keys(%{$vartrans})) {
						if ($tbl->{headings}->[$i] eq "Max ".$vartype) {
							$vartrans->{$vartype}->[2] = $i;
						} elsif ($tbl->{headings}->[$i] eq "Min ".$vartype) {
							$vartrans->{$vartype}->[1] = $i;
						}
					}
				}
			}
			if ($idColumn >= 0) {
				for (my $i=0; $i < @{$tbl->{data}}; $i++) {
					my $row = $tbl->{data}->[$i];
					if (defined($row->[$idColumn])) {
						my $comp = $row->[$compColumn];
						my $id = $row->[$idColumn]."_".$comp."0";
						if ($row->[$idColumn] =~ m/(.+)_(\d+)/) {
							my $cpd = $1;
							my $index = $2;
							if ($index > 0) {
								$id = $cpd."_".$comp.$index;
							}
						}
						my $mdlcpd = $self->fbamodel()->getObject("modelcompounds",$id);
						if (defined($mdlcpd)) {
							foreach my $vartype (keys(%{$vartrans})) {
								if ($vartrans->{$vartype}->[1] != -1 && $vartrans->{$vartype}->[2] != -1) {
									my $min = $row->[$vartrans->{$vartype}->[1]];
									my $max = $row->[$vartrans->{$vartype}->[2]];
									if ($min != 10000000) {
										if (abs($min) < 0.0000001) {
											$min = 0;	
										}
										if (abs($max) < 0.0000001) {
											$max = 0;	
										}
										my $fbaCpdVar = $self->queryObject("FBACompoundVariables",{
											modelcompound_ref => $mdlcpd->_reference(),
											variableType => $vartrans->{$vartype}->[0],
										});
										if (!defined($fbaCpdVar)) {
											$fbaCpdVar = $self->add("FBACompoundVariables",{
												modelcompound_ref => $mdlcpd->_reference(),
												variableType => $vartrans->{$vartype}->[0],
											});	
										}
										$fbaCpdVar->min($min);
										$fbaCpdVar->max($max);
										if (defined($deadCpd->{$id})) {
											$fbaCpdVar->class("Dead");
										} elsif (defined($deadendCpd->{$id})) {
											$fbaCpdVar->class("Deadend");
										} elsif ($fbaCpdVar->min() > 0) {
											$fbaCpdVar->class("Positive");
										} elsif ($fbaCpdVar->max() < 0) {
											$fbaCpdVar->class("Negative");
										} elsif ($fbaCpdVar->min() == 0 && $fbaCpdVar->max() > 0) {
											$fbaCpdVar->class("Positive variable");
										} elsif ($fbaCpdVar->max() == 0 && $fbaCpdVar->min() < 0) {
											$fbaCpdVar->class("Negative variable");
										} elsif ($fbaCpdVar->max() == 0 && $fbaCpdVar->min() == 0) {
											$fbaCpdVar->class("Blocked");
										} else {
											$fbaCpdVar->class("Variable");
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

=head3 parsePROMResult

Definition:
	void parsePROMResult();
Description:
	Parses PROM result file.

=cut

sub parsePROMResult {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	if (-e $directory."/PROMResult.txt") {
		#Loading file results into a hash
		my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/PROMResult.txt");
		if (@{$data} < 3) {
			return Bio::KBase::ObjectAPI::utilities::ERROR("output file did not contain necessary data");
		}
		my $promOutputHash;
		foreach my $row (@{$data}) {
		    my @line = split /\t/, $row;
		    $promOutputHash->{$line[0]} = $line[1] if ($line[0] =~ /alpha|beta|objectFraction/);
		}		
		$self->add("FBAPromResults",$promOutputHash);			       
		return 1;
	}
	return 0;
}



=head3 parseOutputFiles

Definition:
	void parseOutputFiles();
Description:
	Parses output files specified in FBAFormulation

=cut

sub parseOutputFiles {
	my ($self) = @_;
	my $directory = $self->jobDirectory();
	foreach my $filename (keys(%{$self->outputfiles()})) {
		if (-e $directory."/".$filename) {
			$self->outputfiles()->{$filename} = Bio::KBase::ObjectAPI::utilities::LOADFILE($directory."/".$filename);
		}
	}
	if (-e $directory."/suboptimalSolutions.txt") {
		$self->outputfiles()->{"suboptimalSolutions.txt"} = 1;
	}
}

__PACKAGE__->meta->make_immutable;
1;