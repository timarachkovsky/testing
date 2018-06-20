# ComputeFramework release to-do list


## Release workflow

Developer has to perform the following steps before merging the current branch with `development` or `master` branches.

1. Update the following files to the release version:
	* `ComputeFramework/Classifier/Library/preProcessing/standardConfig.xml`
	* `ComputeFramework/Classifier/Library/preProcessing/standardInformativeTags.xml`;
	* `ComputeFramework/Classifier/Library/translations/translations_en(_ru,_de).xml`
1. Rut framework automated tests `ComputeFramework/FuntionalTesting/`
	* (!) Move to the next step ONLY if all automated tests have completed successfully (!)
1. Update folder `ComputeFramework/Classifier/Test/`:
	1. Use [filezilla](https://filezilla-project.org/) to download required rawdata and scripts from `/data/Datasets/CF_Test_Generation/`
	2. Update the following folders in `/Test`:
		- `Test/Full/History/` ------- all methods + history.
		- `Test/Full/Single/` --------- all methods.
		- `Test/Init/History/` ------- metrics + DM + history.
		- `Test/Init/Single/` --------- metrics + DM.
1. Update ComputeFramework documentation:
	1. [Download](https://drive.google.com/drive/u/1/folders/0B817SF22LX3Hdlh3SXZ4S1Z1bDQ) ComputeFramework documentation for current release version. 
	2. Update `API/` and `SPEC/` folders in `ComputeFramework/Docs/`.
	3. Update `ComputeFramework/Docs/[CHANGELOG.md](https://github.com/VibroBox/ComputeFramework/blob/development/Docs/CHANGELOG.md)]
1. Check kinematic schemes in `ComputeFramework/Equipment/` and update them to the release version.
	

## References

1. Documentation for ComputeFramework release management [Release-Management.md](https://github.com/VibroBox/ComputeFramework/blob/development/Docs/Release-Management.md)
2. Documentation for versioning [Semantic Versioning 2.0.0](http://semver.org/) 
