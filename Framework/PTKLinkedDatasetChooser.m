classdef PTKLinkedDatasetChooser < handle
    % PTKLinkedDatasetChooser. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKLinkedDatasetChooser is used to select between linked datasets.
    %     By default, each dataset acts independently, but you can link datasets
    %     together (for example, if you wanted to register images between two
    %     datasets). When datasets are linked, one is the primary dataset, and
    %     linked results are stored in the primary cache. Plugins can choose
    %     which of the linked datasets from which they access results.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Access = private)
        PrimaryDatasetResults % Handle to the PTKDatasetResults object for this dataset
        LinkedDatasetChooserList % Handles to PTKLinkedDatasetChooser objects for all linked datasets, including this one
        PrimaryDatasetUid     % The uid of this dataset
    end
    
    methods
        function obj = PTKLinkedDatasetChooser(primary_dataset_results)
            obj.PrimaryDatasetUid = primary_dataset_results.GetImageInfo.ImageUid;
            obj.PrimaryDatasetResults = primary_dataset_results;
            obj.LinkedDatasetChooserList = containers.Map;
            obj.LinkedDatasetChooserList(obj.PrimaryDatasetUid) = obj;
        end

        function AddLinkedDataset(obj, linked_name, linked_dataset_chooser)
            linked_uid = linked_dataset_chooser.PrimaryDatasetUid;
            obj.LinkedDatasetChooserList(linked_uid) = linked_dataset_chooser;
            obj.LinkedDatasetChooserList(linked_name) = linked_dataset_chooser;
        end

        % RunPlugin: Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.
        function [result, cache_info, output_image] = GetResult(obj, plugin_name, dataset_call_stack, context, dataset_name)
            linked_dataset = obj.FindLinkedDatasetChooser(dataset_name);
            
            if nargout > 2
                [result, cache_info, output_image] = linked_dataset.PrimaryDatasetResults.GetResult(plugin_name, linked_dataset, dataset_call_stack, context);
            else
                [result, cache_info] = linked_dataset.PrimaryDatasetResults.GetResult(plugin_name, linked_dataset, dataset_call_stack, context);
            end
        end

        % Save data as a cache file associated with the dataset
        function SaveData(obj, name, data, dataset_name)
            obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.SaveData(name, data);
        end

        % Load data from a cache file associated with the dataset
        function data = LoadData(obj, name, dataset_name)
            data = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.LoadData(name, obj.Reporting);
        end

        % Gets the path of the folder where the results for this dataset are
        % stored
        function dataset_cache_path = GetDatasetCachePath(obj, dataset_name)
            dataset_cache_path = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.GetCachePath;
        end

        % Gets the path of the folder where the output files for this dataset are
        % stored
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, dataset_name)
            dataset_cache_path = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.GetOutputPathAndCreateIfNecessary;
        end

        % Returns a PTKImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj, dataset_name)
            image_info = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.GetImageInfo;
        end

        % Returns an empty template image for the specified context
        % See PTKImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context, dataset_stack, dataset_name)
            template_image = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.GetTemplateImage(context, linked_dataset, dataset_stack);
        end

        % Gets a thumbnail image of the last result for this plugin
        function preview = GetPluginPreview(obj, plugin_name, dataset_name)
            preview = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.GetPluginPreview(plugin_name);
        end

        % Removes all the cache files associated with this dataset. Cache files
        % store the results of plugins so they need only be computed once for
        % each dataset. Clearing the cache files forces recomputation of all
        % results.
        function ClearCacheForThisDataset(obj, remove_framework_files, dataset_name)
            obj.FindLinkedDatasetChooser(dataset_name).ClearCacheForThisDataset(remove_framework_files);
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context, dataset_name)
            context_is_enabled = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.IsContextEnabled(context);
        end
        
        % ToDo: This check is based on series description and should be more
        % general
        function is_gas_mri = IsGasMRI(obj, dataset_stack, dataset_name)
            linked_dataset = obj.FindLinkedDatasetChooser(dataset_name);
            is_gas_mri = obj.FindLinkedDatasetChooser(dataset_name).PrimaryDatasetResults.IsGasMRI(linked_dataset, dataset_stack);
        end
        
        
        % Checks the dependencies in this result with the current dependency
        % list, and determine if the dependencies are still valid
        function valid = CheckDependenciesValid(obj, dependencies)
            
            dependency_list = dependencies.DependencyList;
            
            for index = 1 : length(dependency_list)
                next_dependency = dependency_list(index);
                
                dataset_uid = next_dependency.DatasetUid;
                linked_dataset = obj.FindLinkedDatasetChooser(dataset_uid);
                if ~linked_dataset.PrimaryDatasetResults.CheckDependencyValid(next_dependency);
                    valid = false;
                    return;
                end
            end
            
            valid = true;
        end
    end

    methods (Access = private)
        function linked_dataset_chooser = FindLinkedDatasetChooser(obj, dataset_name)
            if isempty(dataset_name)
                dataset_name = obj.PrimaryDatasetUid;
            end
            if ~obj.LinkedDatasetChooserList.isKey(dataset_name)
                error; 
            end
            linked_dataset_chooser = obj.LinkedDatasetChooserList(dataset_name);
        end
    end
end
