#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Julia for Global Health Research and Collaboration
# 
# ## 2023 OHDSI DevCon
# 
# ### Jacob S. Zelko


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # My Name Is Jacob Zelko!
# 
# - TheCedarPrince; Open Source Developer (Javis.jl, JuliaHealth, the cedar ledge)
# 
# - Chair of Julia Community Development Fund & Mentor for Julia Gender Inclusive
# 
# - Researcher @ GTRI and CDC
# 
# - Applied Math MS @ NEU (Roux Institute)


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ![](resized_about.jpeg)


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # What Are the Goals of OHDSI?


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# 1. **International open science collaborative dedicated to observational health research**


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# 2. Establish open community data standards

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# 3. **Make end to end solutions of translating observational data to reliable evidence**


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # What Am I Doing in OHDSI?
# 
# Develop package to characterize populations with mental health conditions, investigate prevalence of mental health care, and utilization of mental health resources in rural and urban communities.
# 
# 1. Identify vulnerable populations and their characteristics
# 
# 2. Examine loss to follow up
# 
# 3. Conduct large scale observational health research


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Where Is the Project Today?
# 
# - Deploying study with collaborators across the globe
# 
# - Final weeks of ongoing study!
# 
# - Stretch Goal: 100 million patients


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # What Is Julia? 

# ![](julia_gif.gif)

# _Walks like Python, talks like Lisp, runs like Fortran_


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Brief History
# 
# - Created at MIT in 2012
# 
# - Designed for scientific, numerical and high performance computing
# 
# - Addresses the "Two Language" problem


#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Two Language Problem?
# 
# - You start out prototyping in one language
# 
# - Performance needs forces switch to a different one

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "skip"}}
using Pkg
Pkg.activate(".")

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# Julia is supposed to be fast so let's put it to the test: 
"""
Naive implementation of sum. Works for any iterable `x` with any element type.
"""
function my_sum(x)
    result = zero(eltype(x))
    for element in x
        result += element
    end
    return result
end

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# Let's make some fake data to test `my_sum` with: 
data = rand(Float64, 10^3) 
data = data .* 10 |> result -> round.(Int, result);
# And finally let's time `my_sum`: 
using BenchmarkTools
@btime my_sum($data);

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# Hm, can we make it faster? 
function my_fast_sum(x)
    result = zero(eltype(x))
    @inbounds @simd for element in x
        result += element
    end
    result
end
# Let's time it:
@btime my_fast_sum($data);

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# Great! Let's see how these all compare starting with our original `my_sum`:
@btime my_sum($data);
# Then `my_fast_sum`
@btime my_fast_sum($data);

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Building Bridges with Julia
# ![](bridges.jpg)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Building Bridges with Julia

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# ![](jacob.jpg)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ![](hadley.jpg)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Patient Characterization in Julia 
# - Goal: Create characterization of patients across three axes who have had at least one prior diagnosis of strep throat. 
# - Concept Set: $28060$ (Streptococcal sore throat; SNOMED)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# ## Environment Set-Up 
#
# For all Julia projects, you only need a Project.toml and Manifest.toml.
# These specify package dependencies and their versions down to transient dependencies. 
using Pkg 
Pkg.activate(".")

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# We'll be using the following packages: 
#
# - [`DataFrames`](https://github.com/JuliaData/DataFrames.jl) - Julia's dataframe handler for easily manipulating data
# 
# - [`OMOPCDMCohortCreator`](https://github.com/JuliaHealth/OMOPCDMCohortCreator.jl) - Iteratively create patient cohorts from databases utilizing the OMOP CDM
# 
# - [`HealthSampleData`](https://github.com/JuliaHealth/HealthSampleData.jl) - Sample health data for a variety of health formats and use cases
# 
# - [`SQLite`](https://github.com/JuliaDatabases/SQLite.jl) - A Julia interface to the SQLite library

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# # Data 
#
# We'll use data provided from Eunomia that is stored in a SQLite format.
import HealthSampleData: Eunomia
eunomia = Eunomia();

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "fragment"}}
# To connect to the database, we'll do the following: 
import SQLite: DB
conn = DB(eunomia);

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# To generate connection details, we do the following (NOTE: this is boiler plate that will eventually be handled in the background): 
import OMOPCDMCohortCreator as occ

occ.GenerateDatabaseDetails(:sqlite, "");
occ.GenerateTables(conn);

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Finding all Patients with Strep Throat
strep_patients = occ.ConditionFilterPersonIDs(28060, conn);
size(strep_patients) |> num -> println("Number of patients with Strep: $(num[1])")

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Finding race of all Patients with Strep Throat
strep_patients_race = occ.GetPatientRace(strep_patients.person_id, conn)
strep_patients_race[1, :] |> println

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Finding gender of all Patients with Strep Throat
strep_patients_gender = occ.GetPatientGender(strep_patients.person_id, conn)
strep_patients_gender[1, :] |> println

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Creating age groupings of all Patients with Strep Throat
age_groups = [[0, 4], [5, 9], [10, 14],	[15, 19], [20, 24], [25, 29], [30, 34], 
[35, 39], [40, 44], [45, 49], [50, 54], [55, 59], [60, 64], [65, 69], [70, 74], 
[75, 79], [80, 84], [85, 89], [90, 94], [95, 99], [100, 104], [105, 109]]
strep_patients_age_group = occ.GetPatientAgeGroup(strep_patients.person_id, conn; age_groupings = age_groups)
strep_patients_age_group[1, :] |> println

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# Aside, we can generate SQL representations of all queries used so far
occ.GetPatientAgeGroup([1]; age_groupings = age_groups) |> println

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Characterize Each Person by Gender, Race, and Age Group
import DataFrames as DF

strep_patients_characterized = DF.outerjoin(strep_patients_race, strep_patients_gender, strep_patients_age_group; on = :person_id, matchmissing = :equal)
strep_patients_characterized[1, :] |> println

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# # Finalizing Patient Characterization 
# We can now group up our patients into population groups 
strep_patients_characterized = strep_patients_characterized[:, DF.Not(:person_id)]

strep_patient_groups = DF.groupby(strep_patients_characterized, [:race_concept_id, 
:gender_concept_id, 
:age_group]
)

strep_patient_groups = DF.combine(strep_patient_groups, DF.nrow => :count)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "subslide"}}
# ## Execute Safety Audit
audited_strep_patient_groups = occ.ExecuteAudit(strep_patient_groups; hitech = true)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Ways To Get Involved
#
# - Experiment with Julia Health packages and ecosystem
#   - Patient Level Prediction
#   - Coarse Treatment Pathways
#   - HPC ETL Pipeline
# 
# - Drop into JuliaHealth Meetings or Julia Community
# 
# - Running Birds of a Feather event at JuliaCon (Boston)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# 
# # Let's Do Network Studies! 
#
# - Conducting network studies is entirely possible in Julia
# 
# - Growing network of sites are friendly to Julia projects
#   - Georgia Tech Research Institute
#   - Brown University DBMI
#   - Tufts CTSI
# 
# - Enable more people to participate

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Concluding Thoughts
#
# ![](alan.jpg)

#nb # %% Slide [markdown] {"slideshow": {"slide_type": "slide"}}
# # Keep in Touch!
#
# - Email: jacob.zelko@gtri.gatech.edu
# 
# - Website: https://jacobzelko.com/resources/
# 
# - Twitch: https://www.twitch.tv/thecedarprince
# 
# - OHDSI Microsoft Teams
