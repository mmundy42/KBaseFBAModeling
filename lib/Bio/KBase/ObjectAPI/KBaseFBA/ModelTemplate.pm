########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate - This is the moose object corresponding to the ModelTemplate object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T05:53:23
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelTemplate;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelTemplate';

my $cmpTranslation = {
	extracellular => "e",
    cellwall => "w",
    periplasm => "p",
    cytosol => "c",
    golgi => "g",
    endoplasm => "r",
    lysosome => "l",
    nucleus => "n",
    chloroplast => "h",
    mitochondria => "m",
    peroxisome => "x",
    vacuole => "v",
    plastid => "d",
    unknown => "u",
};

#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub roleToReactions {
	my $self = shift;
	my $roleToRxn = [];
	my $complexes = {};
	my $rxns = $self->templateReactions();
	my $rolehash = {};
	for (my $i=0;$i<@{$rxns};$i++) {
		my $rxn = $rxns->[$i];
		my $cpxs = $rxn->complexes();
		for (my $j=0;$j < @{$cpxs};$j++) {
			my $cpx = $cpxs->[$j];
			if (!defined($complexes->{$cpx->_reference()})) {
				$complexes->{$cpx->_reference()} = {
					complex => $cpx->id(),
					name => $cpx->name(),
					reactions => []
				};
			}
			push(@{$complexes->{$cpx->_reference()}->{reactions}},{
				reaction => $rxn->reaction()->id(),
				direction => $rxn->direction(),
				compartment => $rxn->compartment()->id(),
				equation => $rxn->reaction()->definition()
			});	
			my $roles = $cpx->complexroles();
		    for (my $k=0; $k < @{$roles}; $k++) {
		    	my $role = $roles->[$k]->role();
		    	if (!defined($rolehash->{$role->_reference()})) {
		    		$rolehash->{$role->_reference()} = {
		    			role => $role->id(),
		    			name => $role->name(),
		    			complexes => []
		    		};
		    		push(@{$roleToRxn},$rolehash->{$role->_reference()});
		    	}
		    	my $found = 0;
		    	for (my $m=0; $m < @{$rolehash->{$role->_reference()}->{complexes}}; $m++) {
		    		if ($rolehash->{$role->_reference()}->{complexes}->[$m] eq $complexes->{$cpx->_reference()}) {
		    			$found = 1;
		    		}
		    	}
		    	if ($found == 0) {
		    		push(@{$rolehash->{$role->_reference()}->{complexes}},$complexes->{$cpx->_reference()});
		    	}
		    }
		}
	}
	return $roleToRxn;
}

sub adjustBiomass {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args([], {
    	biomass => $self->templateBiomasses()->[0]->_reference(),
    	"new" => 0,
    	"delete" => 0,
		clearBiomassCompounds => 0,
		name => undef,
		type => undef,
		other => undef,
		protein => undef,
		dna => undef,
		rna => undef,
		cofactor => undef,
		energy => undef,
		cellwall => undef,
		lipid => undef,
		compoundsToAdd => [],
		compoundsToRemove => []
	}, @_);
	my $paramlist = [qw(name type other protein dna rna cofactor energy cellwall lipid)];
	my $tempbio;
	if (defined($args->{biomass})) {
		$tempbio = $self->searchForBiomass($args->{biomass});
	}
	if (!defined($tempbio)) {
		if ($args->{"new"} == 1) {
			$tempbio = $self->add("templateBiomasses",{
				name => $args->{name},
				type => $args->{type},
				other => $args->{other},
				protein => $args->{protein},
				dna => $args->{dna},
				rna => $args->{rna},
				cofactor => $args->{cofactor},
				energy => $args->{energy},
				cellwall => $args->{cellwall},
				lipid => $args->{lipid},
				templateBiomassComponents => []
			});
		} else {
			Bio::KBase::ObjectAPI::utilities::error("Biomass ".$args->{biomass}." not found!");
		}	
	}
	if ($args->{"delete"} == 1) {
		$self->remove("templateBiomasses",$tempbio);
		return $tempbio;
	}
	if ($args->{"clearBiomassCompounds"}) {
        $tempbio->clearLinkArray("templateBiomassComponents");
	}
	foreach my $param (@{$paramlist}) {
		if (defined($args->{$param})) {
			$tempbio->$param($args->{$param});
		}
	}
    my $bio = $self->biochemistry();
    my $comps = $tempbio->templateBiomassComponents();
    for (my $i=0; $i < @{$args->{compoundsToRemove}}; $i++) {
        my $cpd = $bio->searchForCompound($args->{compoundsToRemove}->[$i]);
        for (my $j=0; $j < @{$comps}; $j++) {
            my $comp = $comps->[$j];
            if ($comp->compound_ref() eq $cpd->_reference()) {
                $tempbio->remove("templateBiomassComponents", $comp);
            }
        }
    }
    my $compound = $args->{compoundsToAdd};
	if (defined($compound->[0])) {
        my $cpd = $bio->searchForCompound($compound->[0]);
        if (!defined($cpd)) {
            Bio::KBase::ObjectAPI::utilities::error("Compound ".$compound->[0]." not found!");
        }
        my $found = 0;
        for (my $j=0; $j < @{$comps} && $found == 0; $j++) {
            my $comp = $comps->[$j];
            if ($comp->compound_ref() eq $cpd->_reference()) {
                $found = 1;
            }
        }
        if ($found == 0) {
	        my $cmp = $bio->searchForCompartment($compound->[1]);
	        if (!defined($cmp)) {
	            Bio::KBase::ObjectAPI::utilities::error("Compartment ".$compound->[1]." not found!");
	        }
	        my $comp = Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomassComponent->new({
	            class => $compound->[2],
	            compound_ref => $cpd->_reference(),
	            compartment_ref => $cmp->_reference(),
	            coefficientType => $compound->[4],
	            coefficient => $compound->[5],
	        });
			$tempbio->add("templateBiomassComponents", $comp);
	    }
	}
    return $tempbio;
}

sub adjustReaction {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["reaction"], {
    	compartment => "c",
    	direction => undef,
    	type => undef,
    	"new" => 0,
    	complexesToRemove => [],
    	complexesToAdd => [],
    	"delete" => 0,
    	clearComplexes => 0
    }, @_);
	my $bio = $self->biochemistry();
	my $rxn = $bio->searchForReaction($args->{reaction});
	Bio::KBase::ObjectAPI::utilities::error("Specified reaction ".$args->{reaction}." not found!") unless(defined($rxn));
	my $cmp = $bio->searchForCompartment($args->{compartment});
	Bio::KBase::ObjectAPI::utilities::error("Specified compartment ".$args->{compartment}." not found!") unless(defined($cmp));
	my $temprxn = $self->queryObjects("templateReactions",{
		compartment_ref => $cmp->_reference(),
		reaction_ref => $rxn->_reference()
	});
	if (!defined($temprxn)) {
		if (defined($args->{"new"}) && $args->{"new"} == 1) {
			$temprxn = Bio::KBase::ObjectAPI::KBaseFBA::TemplateReaction->new({
				compartment_ref => $cmp->_reference(),
				reaction_ref => $rxn->_reference()
			});
			$self->add("templateReactions",$temprxn);
		} else {
			Bio::KBase::ObjectAPI::utilities::error("Specified template reaction not found and new reaction not specified!");
		}
	} elsif (defined($args->{"delete"}) && $args->{"delete"} == 1) {
		$self->remove("templateReactions",$temprxn);
		return $temprxn;
	}
	if (defined($args->{direction})) {
		$temprxn->direction($args->{direction});
	}
	if (defined($args->{type})) {
		$temprxn->type($args->{type});
	}
    if (defined($args->{clearComplexes}) && $args->{clearComplexes} == 1) {
		$temprxn->clearLinkArray("complexes");
	}
  	for (my $i=0; $i < @{$args->{complexesToRemove}}; $i++) {
  		my $cpx = $self->mapping()->searchForComplex($args->{complexesToRemove}->[$i]);
    	if (defined($cpx)) {
    		$temprxn->removeLinkArrayItem("complexes",$cpx);
    	}
   	}
    for (my $i=0; $i < @{$args->{complexesToAdd}}; $i++) {
    	my $cpx = $self->mapping()->searchForComplex($args->{complexesToAdd}->[$i]);
    	if (defined($cpx)) {
    		$temprxn->addLinkArrayItem("complexes",$cpx);
    	} else {
  			Bio::KBase::ObjectAPI::utilities::error("Specified complex ".$args->{complexesToAdd}->[$i]." not found!");
  		}
   	}
   	return $temprxn;
}

sub buildModel {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["genome","modelid"],{}, @_);
	my $genome = $args->{genome};
	my $mdl = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		id => $args->{modelid},
		source => $genome->source(),
		source_id => $genome->source_id().".fbamdl",
		type => $self->modelType(),
		name => $genome->scientific_name(),
		genome_ref => $genome->_reference(),
		template_ref => $self->_reference(),
		gapfillings => [],
		gapgens => [],
		biomasses => [],
		modelcompartments => [],
		modelcompounds => [],
		modelreactions => []
	});
	$mdl->_reference("~");
	$mdl->parent($self->parent());
	my $rxns = $self->templateReactions();
	my $roleFeatures;
	my $features = $genome->features();
	for (my $i=0; $i < @{$features}; $i++) {
		my $ftr = $features->[$i];
		my $roles = $ftr->roles();
		my $compartments = $ftr->compartments();
		for (my $j=0; $j < @{$roles}; $j++) {
			my $role = $roles->[$j];
			for (my $k=0; $k < @{$compartments}; $k++) {
				my $abbrev = $compartments->[$k];
				if (length($compartments->[$k]) > 1 && defined($cmpTranslation->{$compartments->[$k]})) {
					$abbrev = $cmpTranslation->{$compartments->[$k]};
				} elsif (length($compartments->[$k]) > 1 && !defined($cmpTranslation->{$compartments->[$k]})) {
					print STDERR "Compartment ".$compartments->[$k]." not found!\n";
				}
				my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($role);
				my $roles = $self->mapping()->searchForRoles($searchrole);
				for (my $n=0; $n < @{$roles};$n++) {
					push(@{$roleFeatures->{$roles->[$n]->id()}->{$abbrev}},$ftr);
				}
			}
		}
	}
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		$rxn->addRxnToModel({
			role_features => $roleFeatures,
			model => $mdl
		});
	}
	my $bios = $self->templateBiomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		$bio->addBioToModel({
			gc => $genome->gc_content(),
			model => $mdl
		});
	}
	return $mdl;
}

sub buildModelFromFunctions {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["functions","id"],{}, @_);
	my $mdl = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		id => $args->{modelid},
		source => "KBase",
		source_id => $args->{modelid},
		type => $self->modelType(),
		name => "Unknown",
		template_ref => $self->_reference(),
		gapfillings => [],
		gapgens => [],
		biomasses => [],
		modelcompartments => [],
		modelcompounds => [],
		modelreactions => []
	});
	my $rxns = $self->templateReactions();
	my $roleFeatures = {};
	foreach my $function (keys(%{$args->{functions}})) {
		my $searchrole = Bio::KBase::ObjectAPI::Utilities::GlobalFunctions::convertRoleToSearchRole($function);
		my $subroles = [split(/;/,$searchrole)];
		for (my $m=0; $m < @{$subroles}; $m++) {
			my $roles = $self->mapping()->searchForRoles($subroles->[$m]);
			for (my $n=0; $n < @{$roles};$n++) {
				$roleFeatures->{$roles->[$n]->_reference()}->{"c"}->[0] = "Role-based-annotation";
			}
		}
	}
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		$rxn->addRxnToModel({
			role_features => $roleFeatures,
			model => $mdl
		});
	}
	my $bios = $self->templateBiomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		$bio->addBioToModel({
			gc => 0.5,
			model => $mdl
		});
	}
	return $mdl;
}

=head3 searchForBiomass

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass->searchForBiomass(string:id);
Description:
	Search for biomass in template model
	
=cut

sub searchForBiomass {
    my $self = shift;
    my $id = shift;
    my $obj = $self->queryObject("templateBiomasses",{uuid => $id});
    if (!defined($obj)) {
    	$obj = $self->queryObject("templateBiomasses",{name => $id});
    }
    return $obj;
}

__PACKAGE__->meta->make_immutable;
1;