module fbaModelServices {
    /*********************************************************************************
    Universal simple type definitions
   	*********************************************************************************/
    typedef int bool;
    typedef string workspace_id;
	typedef string object_type;
	typedef string object_id;
	typedef string username;
	typedef string timestamp;
    typedef string compound_id;
    typedef string biochemistry_id;
    typedef string genome_id;
    typedef string contig_id;
    typedef string feature_type;
    typedef string modelcompartment_id;
    typedef string modelcompound_id;
    typedef string feature_id;
    typedef string reaction_id;
    typedef string modelreaction_id;
    typedef string biomass_id;
    typedef string media_id;
    typedef string fba_id;
    typedef string gapgen_id;
    typedef string gapfill_id;
    typedef string fbamodel_id;
    typedef string biochemistry_id;
    typedef string mapping_id;
    typedef string media_id;
    typedef string probabilistic_annotation_id;
    typedef string regmodel_id;
    typedef string compartment_id;
    typedef string expression_id;
    /*********************************************************************************
    Object type definition
   	*********************************************************************************/
    typedef tuple<object_id id,object_type type,timestamp moddate,int instance,string command,username lastmodifier,username owner> object_metadata;
    /*********************************************************************************
    Probabilistic Annotation type definition
   	*********************************************************************************/
    typedef string md5;
    typedef list<md5> md5s;
    /* A region of DNA is maintained as a tuple of four components:

        the contig
        the beginning position (from 1)
        the strand
        the length

        We often speak of "a region".  By "location", we mean a sequence
        of regions from the same genome (perhaps from distinct contigs).
    */
    typedef tuple<contig_id, int begin, string strand,int length> region_of_dna;

    /*
        a "location" refers to a sequence of regions
    */
    typedef list<region_of_dna> location;
    typedef tuple<string comment, string annotator, int annotation_time> annotation;
    typedef tuple<feature_id gene, float blast_score> gene_hit;
    typedef tuple<string function, float probability, list<gene_hit> gene_hits > alt_func;

    typedef structure {
		feature_id id;
		location location;
		feature_type type;
		string function;
		list<alt_func> alternative_functions;
		string protein_translation;
		list<string> aliases;
		list<annotation> annotations;
    } feature;

    typedef structure {
		contig_id id;
		string dna;
    } contig;

    typedef structure {
		genome_id id;
		string scientific_name;
		string domain;
		int genetic_code;
		string source;
		string source_id;
		list<contig> contigs;
		list<feature> features;
    } GenomeObject;
    /*********************************************************************************
    Biochemistry type definition
   	*********************************************************************************/
    typedef structure {
		biochemistry_id id;
		string name;
		list<compound_id> compounds;
		list<reaction_id> reactions;
		list<media_id> media;
    } Biochemistry;
    
    typedef structure {
		media_id id;
		string name;
		list<compound_id> compounds;
		list<float> concentrations;
		float pH;
		float temperature;
    } Media;
    
    typedef structure {
		compound_id id;
		string name;
		list<string> aliases;
		float charge;
		string formula;
    } Compound;
    
    typedef structure {
		reaction_id id;
		string reversibility;
		float deltaG;
		float deltaGErr;
		string equation;	
    } Reaction;
    /*********************************************************************************
    FBAModel type definition
   	*********************************************************************************/
    typedef structure {
		modelcompartment_id id;
		string name;
		float pH;
		float potential;
		int index;
    } ModelCompartment;
    
    typedef structure {
		modelcompound_id id;
		compound_id compound;
		string name;
		modelcompartment_id compartment;
    } ModelCompound;
    
    typedef structure {
		modelreaction_id id;
		reaction_id reaction;
		string name;
		string direction;
		list<feature_id> features;
		modelcompartment_id compartment;
    } ModelReaction;
    
    typedef tuple<modelcompound_id modelcompound,float coefficient> BiomassCompound;
    
    typedef structure {
		biomass_id id;
		string name;
		list<BiomassCompound> biomass_compounds;
    } ModelBiomass;
    
    typedef tuple<fba_id id,workspace_id workspace,media_id media,workspace_id media_workspace,float objective,list<feature_id> ko> FBAMeta;
    typedef tuple<gapgen_id id,workspace_id workspace,media_id media,workspace_id media_workspace,bool done,list<feature_id> ko> GapGenMeta;
    typedef tuple<gapfill_id id,workspace_id workspace,media_id media,workspace_id media_workspace,bool done,list<feature_id> ko> GapFillMeta;
    
    typedef structure {
		fbamodel_id id;
		workspace_id workspace;
		genome_id genome;
		workspace_id genome_workspace;
		mapping_id map;
		workspace_id map_workspace;
		biochemistry_id biochemistry;
		workspace_id biochemistry_workspace;
		string name;
		string type;
		string status;
		
		list<ModelBiomass> biomasses;
		list<ModelCompartment> compartments;
		list<ModelReaction> reactions;
		list<ModelCompound> compounds;
		
		list<FBAMeta> fbas;
		list<GapFillMeta> integrated_gapfillings;
		list<GapFillMeta> unintegrated_gapfillings;
		list<GapGenMeta> integrated_gapgenerations;
		list<GapGenMeta> unintegrated_gapgenerations;
    } FBAModel;
    /*********************************************************************************
    Flux Balance Analysis type definition
   	*********************************************************************************/
    typedef tuple<feature_id feature,float growthFraction,float growth,bool isEssential> GeneAssertion;
    typedef tuple<modelcompound_id compound,float value,float upperBound,float lowerBound,float max,float min,string type> CompoundFlux;
    typedef tuple<modelreaction_id reaction,float value,float upperBound,float lowerBound,float max,float min,string type> ReactionFlux;
    typedef tuple<float maximumProduction,modelcompound_id modelcompound> MetaboliteProduction;

    typedef string compound_id;
	    typedef structure {
		list<compound_id> optionalNutrients;
		list<compound_id> essentialNutrients;
    } MinimalMediaPrediction;
    
    typedef tuple<float min,float max,string varType,string variable> bound;
    typedef tuple<float coefficient,string varType,string variable> term;
    typedef tuple<float rhs,string sign,list<term> terms,string name> constraint;
	
	typedef structure {
		media_id media;
		workspace_id media_workspace;
		float objfraction;
		bool allreversible;
		bool maximizeObjective;
		list<term> objectiveTerms;
		list<feature_id> geneko;
		list<reaction_id> rxnko;
		list<bound> bounds;
		list<constraint> constraints;
		mapping<string,float> uptakelim;
		float defaultmaxflux;
		float defaultminuptake;
		float defaultmaxuptake;
		bool simplethermoconst;
		bool thermoconst;
		bool nothermoerror;
		bool minthermoerror;
    } FBAFormulation;
    
    typedef structure {
		fba_id id;
		workspace_id workspace;
        fbamodel_id model;
        workspace_id model_workspace;
        float objective;
        bool isComplete;
		FBAFormulation formulation;
		list<MinimalMediaPrediction> minimalMediaPredictions;
		list<MetaboliteProduction> metaboliteProductions;
		list<ReactionFlux> reactionFluxes;
		list<CompoundFlux> compoundFluxes;
		list<GeneAssertion> geneAssertions;
    } FBA;
    /*********************************************************************************
    Gapfilling type definition
   	*********************************************************************************/
    typedef structure {
		FBAFormulation formulation;
		bool nomediahyp;
		bool nobiomasshyp;
		bool nogprhyp;
		bool nopathwayhyp;
		bool allowunbalanced;
		float activitybonus;
		float drainpen;
		float directionpen;
		float nostructpen;
		float unfavorablepen;
		float nodeltagpen;
		float biomasstranspen;
		float singletranspen;
		float transpen;
		list<reaction_id> blacklistedrxns;
		list<reaction_id> gauranteedrxns;
		list<compartment_id> allowedcmps;
		probabilistic_annotation_id probabilistic_annotation;
    } GapfillingFormulation;
    
    typedef tuple<reaction_id reaction,string direction> reactionAddition;
    
    typedef structure {
        float objective;
		list<modelcompound_id> biomassRemovals;
		list<compound_id> mediaAdditions;
		list<reactionAddition> reactionAdditions;
    } GapFillSolution;
    
    typedef structure {
		gapfill_id id;
		workspace_id workspace;
		fbamodel_id model;
        workspace_id model_workspace;
        bool isComplete;
		GapfillingFormulation formulation;
		list<GapFillSolution> solutions;
    } GapFill;
    /*********************************************************************************
    Gap Generation type definition
   	*********************************************************************************/
    typedef structure {
		FBAFormulation formulation;
		bool nomediahyp;
		bool nobiomasshyp;
		bool nogprhyp;
		bool nopathwayhyp;
    } GapgenFormulation;
    
    typedef tuple<modelreaction_id reaction,string direction> reactionRemoval;
    
    typedef structure {
        float objective;
		list<compound_id> biomassAdditions;
		list<compound_id> mediaRemovals;
		list<reactionRemoval> reactionRemovals;
    } GapgenSolution;
    
    typedef structure {
		gapgen_id id;
		workspace_id workspace;
		fbamodel_id model;
        workspace_id model_workspace;
        bool isComplete;
		GapgenFormulation formulation;
		list<GapgenSolution> solutions;
    } GapGen;
    /*********************************************************************************
    Function definitions relating to data retrieval for Model Objects
   	*********************************************************************************/
    typedef structure {
		list<fbamodel_id> models;
		list<workspace_id> workspaces;
		string authentication;
        string id_type;
    } get_models_params;
    /*
    	Returns model data for input ids
    */
    funcdef get_models(get_models_params input) returns (list<FBAModel> out_models);

    typedef structure {
		list<fba_id> fbas;
		list<workspace_id> workspaces; 
		string authentication;
        string id_type;
    } get_fbas_params;
    /*
    	Returns data for the requested flux balance analysis formulations
    */
    funcdef get_fbas(get_fbas_params input) returns (list<FBA> out_fbas);

    typedef structure {
		list<gapfill_id> gapfills;
		list<workspace_id> workspaces; 
		string authentication;
        string id_type;
    } get_gapfills_params;
    /*
    	Returns data for the requested gap filling simulations
    */
    funcdef get_gapfills(get_gapfills_params input) returns (list<GapFill> out_gapfills);

    typedef structure {
		list<gapgen_id> gapgens;
		list<workspace_id> workspaces;
		string authentication;
        string id_type;
    } get_gapgens_params;
    /*
    	Returns data for the requested gap generation simulations
    */
    funcdef get_gapgens(get_gapgens_params input) returns (list<GapGen> out_gapgens);

    typedef structure {
		list<reaction_id> reactions;
		string authentication;
        string id_type;
    } get_reactions_params;
    /*
    	Returns data for the requested reactions
    */
    funcdef get_reactions(get_reactions_params input) returns (list<Reaction> out_reactions);

    typedef structure {
		list<compound_id> compounds;
		string authentication;
        string id_type;
    } get_compounds_params;
    /*
    	Returns data for the requested compounds
    */
    funcdef get_compounds(get_compounds_params input) returns (list<Compound> out_compounds);

    /*This function returns media data for input ids*/
    typedef structure {
		list<media_id> medias;
		list<workspace_id> workspaces;
		string authentication;
    } get_media_params;
    /*
    	Returns data for the requested media formulations
    */
    funcdef get_media(get_media_params input) returns (list<Media> out_media);

    typedef structure {
        biochemistry_id biochemistry;
        workspace_id biochemistry_workspace;
        string id_type;
        string authentication;
    } get_biochemistry_params;
    /*
    	Returns biochemistry object
    */
    funcdef get_biochemistry(get_biochemistry_params input) returns (Biochemistry out_biochemistry);
	/*********************************************************************************
    Code relating to reconstruction of metabolic models
   	*********************************************************************************/
    typedef string workspace_id;
    typedef structure {
		genome_id id;
    } genomeTO;
    typedef structure {
		genomeTO genomeobj;
		workspace_id workspace;
		string authentication;
		bool overwrite;
    } genome_object_to_workspace_params;
    /*
        Loads an input genome object into the workspace.
    */
    funcdef genome_object_to_workspace(genome_object_to_workspace_params input) returns (object_metadata genomeMeta);
    
    typedef structure {
		genome_id genome;
		workspace_id workspace;
		string authentication;
		bool overwrite;
    } genome_to_workspace_params;
    /*
        Retrieves a genome from the CDM and saves it as a genome object in the workspace.
    */
    funcdef genome_to_workspace(genome_to_workspace_params input) returns (object_metadata genomeMeta);
    
    /*
        A set of paramters for the genome_to_fbamodel method. This is a mapping
        where the keys in the map are named 'in_genome', 'in_workspace', 'out_model',
        and 'out_workspace'. Values for each are described below.
    
        genome_id in_genome
        This parameter specifies the ID of the genome for which a model is to be built. This parameter is required.
    
        workspace_id in_workspace
        This parameter specifies the ID of the workspace containing the specified genome object. This parameter is also required.
    
        fbamodel_id out_model
        This parameter specifies the ID to which the generated model should be save. This is optional.
        If unspecified, a new KBase model ID will be checked out for the model.
    
        workspace_id out_workspace
        This parameter specifies the ID of the workspace where the model should be save. This is optional.
        If unspecified, this parameter will be set to the value of "in_workspace".
    */
    typedef structure {
		genome_id genome;
		workspace_id genome_workspace;
		fbamodel_id model;
		workspace_id model_workspace;
		string authentication;
		bool overwrite;
    } genome_to_fbamodel_params;
    /*
        This function accepts a genome_to_fbamodel_params as input, building a new FBAModel for the genome specified by genome_id.
        The function returns a genome_to_fbamodel_params as output, specifying the ID of the model generated in the model_id parameter.
    */
    funcdef genome_to_fbamodel (genome_to_fbamodel_params input) returns (object_metadata modelMeta);
    
    /*
        NEED DOCUMENTATION
    */
    typedef structure {
		fbamodel_id model;
		workspace_id workspace;
		string format;
		string authentication;
    } export_fbamodel_params;
    
    /*
        This function exports the specified FBAModel to a specified format (sbml,html)
    */
    funcdef export_fbamodel(export_fbamodel_params input) returns (string output);
    
    /*********************************************************************************
    Code relating to flux balance analysis
   	*********************************************************************************/
    
    typedef structure {
		media_id media;
		workspace_id workspace;
		string name;
		bool isDefined;
		bool isMinimal;
		string type;
		list<string> compounds;
		list<float> concentrations;
		list<float> maxflux;
		list<float> minflux;
		bool overwrite;
		string authentication;
    } addmedia_params;
    /*
        Add media condition to workspace
    */
    funcdef addmedia(addmedia_params input) returns (object_metadata mediaMeta);
    
    typedef structure {
		media_id media;
		workspace_id workspace;
		string format;
		string authentication;
    } export_media_params;
    /*
        Exports media in specified format (html,readable)
    */
    funcdef export_media(export_media_params input) returns (string output);
    
    /*
        NEED DOCUMENTATION
    */
    typedef structure {
    	fbamodel_id model;
		workspace_id model_workspace;
		FBAFormulation formulation;
		bool fva;
		bool simulateko;
		bool minimizeflux;
		bool findminmedia;
		string notes;
		fba_id fba;
		workspace_id fba_workspace;
		string authentication;
		bool overwrite;
		bool add_to_model;
    } runfba_params;
    /*
        Run flux balance analysis and return ID of FBA object with results 
    */
    funcdef runfba(runfba_params input) returns (object_metadata fbaMeta);
    
    typedef structure {
		fba_id fba;
		workspace_id workspace;
		string format;
		string authentication;
    } export_fba_params;
    /*
        Export an FBA solution for viewing
    */
    funcdef export_fba(export_fba_params input) returns (string output);
    
    /*********************************************************************************
    Code relating to phenotype simulation and reconciliation
   	*********************************************************************************/
    typedef string phenotypeSet_id;
    typedef tuple< list<feature_id> geneKO,media_id baseMedia,workspace_id media_workspace,list<compound_id> additionalCpd,float normalizedGrowth> Phenotype;
    typedef structure {
		phenotypeSet_id id;
		genome_id genome;
		workspace_id genome_workspace;
		list<Phenotype> phenotypes;
		string importErrors;
    } PhenotypeSet;
    
    typedef string phenotypeSimulationSet_id;
    typedef tuple< Phenotype,float simulatedGrowth,float simulatedGrowthFraction,string class> PhenotypeSimulation;
    typedef structure {
    	phenotypeSimulationSet_id id;
		fbamodel_id model;
		workspace_id model_workspace;
		phenotypeSet_id phenotypeSet;
		list<PhenotypeSimulation> phenotypeSimulations;
    } PhenotypeSimulationSet;
    
    typedef structure {
		phenotypeSet_id phenotypeSet;
		workspace_id phenotypeSet_workspace;
		genome_id genome;
		workspace_id genome_workspace;
		list<Phenotype> phenotypes;
		bool ignore_errors;
		string authentication;
    } import_phenotypes_params;
    /*
        Loads the specified phenotypes into the workspace
    */
    funcdef import_phenotypes (import_phenotypes_params input) returns (object_metadata output);
    
    typedef structure {
		fbamodel_id model;
		workspace_id model_workspace;
		phenotypeSet_id phenotypeSet;
		workspace_id phenotypeSet_workspace;
		FBAFormulation formulation;
		string notes;
		phenotypeSimulationSet_id phenotypeSimultationSet;
		workspace_id phenotypeSimultationSet_workspace;
		bool overwrite;
		string authentication;
    } simulate_phenotypes_params;
    /*
        Simulates the specified phenotype set
    */
    funcdef simulate_phenotypes (simulate_phenotypes_params input) returns (object_metadata output);
    
    typedef structure {
		phenotypeSimulationSet_id phenotypeSimulationSet;
		workspace_id workspace;
		string format;
		string authentication;
    } export_phenotypeSimulationSet_params;
    /*
        Export a PhenotypeSimulationSet for viewing
    */
    funcdef export_phenotypeSimulationSet (export_phenotypeSimulationSet_params input) returns (string output);
    
    /*********************************************************************************
    Code relating to queuing long running jobs
   	*********************************************************************************/ 
    typedef string job_id;
    typedef structure {
		string authentication;
    } CommandArguments;
    typedef structure {
		string authentication;
    } clusterjob;
    typedef structure {
		job_id id;
		workspace_id kbase_workspace;
		list<clusterjob> clusterjobs;
		string postprocess_command;
		list<CommandArguments> postprocess_args;
		string queuing_command;
		float clustermem;
		int clustertime;
		string clustertoken;
		string queuetime;
		string completetime;
		bool complete;
		string owner;		
    } JobObject;
	/*
        Queues an FBA job in a single media condition
    */
	funcdef queue_runfba(runfba_params input) returns (JobObject output);
   
    typedef structure {
		phenotypeSet_id id;
		fbamodel_id in_model;
		workspace_id in_workspace;
		FBAFormulation in_formulation;
		int num_solutions;
		bool no_media_hypothesis;
		bool no_biomass_hypothesis;
		bool no_gpr_hypothesis;
		bool no_pathway_hypothesis;
		bool allow_unbalanced;
		float activity_bonus;
		float drain_penalty;
		float direction_penalty;
		float no_structure_penalty;
		float unfavorable_penalty;
		float no_deltag_penalty;
		float biomass_transport_penalty;
		float single_transport_penalty;
		float transport_penalty;
		list<reaction_id> blacklistedrxns;
		list<reaction_id> gauranteedrxns;
		list<string> allowed_compartments;
		bool integrate_solution;
		string notes;
		genome_id prob_anno;
		workspace_id prob_anno_workspace;
		fbamodel_id out_model;
		workspace_id out_workspace;
		string authentication;
		bool overwrite;
		bool donot_submit_job;
		int gapfilling_index;
		job_id job;
    } gapfill_model_params;
    /*
        Queues an FBAModel gapfilling job in single media condition
    */
    funcdef queue_gapfill_model(gapfill_model_params input) returns (JobObject output);
    
    typedef structure {
		phenotypeSet_id id;
		fbamodel_id in_model;
		workspace_id in_workspace;
		FBAFormulation in_formulation;
		int num_solutions;
		bool no_media_hypothesis;
		bool no_biomass_hypothesis;
		bool no_gpr_hypothesis;
		bool no_pathway_hypothesis;
		bool integrate_solution;
		string notes;
		fbamodel_id out_model;
		workspace_id out_workspace;
		string authentication;
		bool overwrite;
		bool donot_submit_job;
		int gapgen_index;
    } gapgen_model_params;
    /*
        Queues an FBAModel gapfilling job in single media condition
    */
    funcdef queue_gapgen_model(gapgen_model_params input) returns (JobObject output);
    
    typedef structure {
		phenotypeSet_id id;
		fbamodel_id in_model;
		workspace_id in_workspace;
		FBAFormulation in_formulation;
		int num_solutions;
		bool no_media_hypothesis;
		bool no_biomass_hypothesis;
		bool no_gpr_hypothesis;
		bool no_pathway_hypothesis;
		bool allow_unbalanced;
		float activity_bonus;
		float drain_penalty;
		float direction_penalty;
		float no_structure_penalty;
		float unfavorable_penalty;
		float no_deltag_penalty;
		float biomass_transport_penalty;
		float single_transport_penalty;
		float transport_penalty;
		list<reaction_id> blacklistedrxns;
		list<reaction_id> gauranteedrxns;
		list<string> allowed_compartments;
		string notes;
		genome_id prob_anno;
		workspace_id prob_anno_workspace;
		fbamodel_id out_model;
		workspace_id out_workspace;
		string authentication;
		bool overwrite;
		bool donot_submit_job;
		list<int> all_gapgen_indecies;
		list<int> all_gapfill_indecies;
		int gapgen_index;
		int gapfill_index;
    } wildtype_phenotype_reconciliation_params;
    /*
        Queues an FBAModel reconciliation job
    */
    funcdef queue_wildtype_phenotype_reconciliation(wildtype_phenotype_reconciliation_params input) returns (JobObject output);
    
    typedef structure {
		fbamodel_id in_model;
		workspace_id in_workspace;
		FBAFormulation in_formulation;
		int num_solutions;
		bool integrate_solution;
		string notes;
		fbamodel_id out_model;
		workspace_id out_workspace;
		string authentication;
		bool donot_submit_job;
		bool overwrite;
    } combine_wildtype_phenotype_reconciliation_params;
    /*
        Queues an FBAModel reconciliation job
    */
    funcdef queue_combine_wildtype_phenotype_reconciliation_params(combine_wildtype_phenotype_reconciliation_params input) returns (JobObject output);
    	
	typedef string job_id;
	typedef structure {
		job_id jobid;
		workspace_id workspace;
		string authentication;
    } jobs_done_params;
	/*
        Mark specified job as complete and run postprocessing
    */
	funcdef jobs_done(jobs_done_params input) returns (JobObject output);

	typedef structure {
		job_id jobid;
		workspace_id workspace;
		string authentication;
    } check_job_params;
    /*
        Retreives job data given a job ID
    */
    funcdef check_job(check_job_params input) returns (JobObject output);       
	
	typedef structure {
		job_id jobid;
		workspace_id workspace;
		int index;
		string authentication;
    } run_job_params;
	/*
        Runs specified job
    */
	funcdef run_job(run_job_params input) returns (JobObject output);
};
