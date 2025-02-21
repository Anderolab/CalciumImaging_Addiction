function plotMeanFluorescenceByRecording(Experiment_trial)
    % Definir la lista de experimentos
    experiment_names = fieldnames(Experiment_trial);

    % Seleccionar las sesiones que se desean analizar
    selected_sessions_idx = listdlg('PromptString', 'Selecciona las sesiones a analizar:', ...
                                    'SelectionMode', 'multiple', ...
                                    'ListString', experiment_names);
    if isempty(selected_sessions_idx)
        disp('No se seleccionaron sesiones. Proceso cancelado.');
        return;
    end

    % Inicializar estructuras para almacenar las medias de cada grabación y sus etiquetas
    recording_means = [];
    recording_labels = {};  % Inicializar como celda vacía para evitar el error
    
    % Estructura temporal para almacenar los datos de fluorescencia media por neurona
    fluorescence_data = struct();

    % Proceso para cada sesión seleccionada
    max_neurons = 0;  % Almacena el máximo número de neuronas entre grabaciones
    for session_idx = 1:length(selected_sessions_idx)
        i = selected_sessions_idx(session_idx);
        experiment = Experiment_trial.(experiment_names{i});

        % Obtener los nombres de las grabaciones de calcio (subfolders)
        subfolder_names = fieldnames(experiment);
        subfolder_names = subfolder_names(~ismember(subfolder_names, {'StartTime', 'EndTime', 'R', 'K', 'U', 'W', 'L', 'N', 'J'}));

        % Seleccionar las grabaciones de calcio que se desean analizar
        selected_subfolders_idx = listdlg('PromptString', ['Selecciona las grabaciones para ', experiment_names{i}], ...
                                          'SelectionMode', 'multiple', ...
                                          'ListString', subfolder_names);
        if isempty(selected_subfolders_idx)
            disp(['No se seleccionaron grabaciones para ', experiment_names{i}, '. Se omitirá esta sesión.']);
            continue;
        end

        % Proceso de selección de neuronas buenas para cada grabación (subcarpeta)
        good_neurons_files = cell(1, length(subfolder_names));
        for j = selected_subfolders_idx
            % Solicitar el archivo de buenas neuronas (opcional)
            [file, path] = uigetfile('*.mat', ['Selecciona archivo de buenas neuronas para ', subfolder_names{j}], 'MultiSelect', 'off');
            if isequal(file, 0)  % Si el usuario cancela la selección
                disp(['No se seleccionó archivo para ', subfolder_names{j}, '. Se usarán todas las neuronas.']);
                good_neurons_files{j} = []; % Guardar un valor vacío si no se selecciona archivo
            else
                % Cargar archivo de buenas neuronas
                good_neurons_files{j} = load(fullfile(path, file));
                disp(['Archivo de buenas neuronas seleccionado para ', subfolder_names{j}]);
            end
        end

        % Procesar las grabaciones seleccionadas
        num_recordings = length(selected_subfolders_idx);
        for j = 1:num_recordings
            subfolder = experiment.(subfolder_names{selected_subfolders_idx(j)});

            % Aplicar filtro de neuronas buenas si se seleccionó un archivo
            if ~isempty(good_neurons_files{selected_subfolders_idx(j)})
                good_neurons = good_neurons_files{selected_subfolders_idx(j)}.good_neurons; % Usar la variable good_neurons del archivo cargado
                FiltTraces_good = subfolder.FiltTraces(:, good_neurons); % Filtrar trazas de neuronas buenas
                global_fluorescence = mean(FiltTraces_good, 2); % Fluorescencia global solo con neuronas buenas
                disp(['Usando solo las neuronas buenas para ', subfolder_names{selected_subfolders_idx(j)}]);
            else
                FiltTraces_good = subfolder.FiltTraces; % Usar todas las neuronas
                global_fluorescence = mean(FiltTraces_good, 2);
                disp(['Usando todas las neuronas para ', subfolder_names{selected_subfolders_idx(j)}]);
            end

            % Calcular la media de fluorescencia para la grabación actual
            recording_mean_fluorescence = mean(global_fluorescence);
            recording_means = [recording_means; recording_mean_fluorescence];

            % Guardar la fluorescencia media por neurona (promedio por frame)
            neuron_mean_fluorescence = mean(FiltTraces_good, 1)';
            
            % Actualizar el máximo número de neuronas
            max_neurons = max(max_neurons, length(neuron_mean_fluorescence));

            % Etiqueta para Excel, indicando sesión y grabación
            column_label = [experiment_names{i} '_' subfolder_names{selected_subfolders_idx(j)}];
            fluorescence_data.(column_label) = neuron_mean_fluorescence;

            % Generar la etiqueta de la grabación en formato "recordingX"
            recording_labels{end+1} = [' recording' num2str(j)];
            disp(['Media de fluorescencia para la grabación ', subfolder_names{selected_subfolders_idx(j)}, ...
                ' en la sesión ', experiment_names{i}, ': ', num2str(recording_mean_fluorescence)]);
        end
    end

    % Crear la tabla para Excel con el mismo número de filas (relleno con NaN)
    excel_data = table();
    fields = fieldnames(fluorescence_data);
    for k = 1:length(fields)
        column_data = fluorescence_data.(fields{k});
        if length(column_data) < max_neurons
            % Rellenar con NaN para igualar el tamaño
            column_data = [column_data; NaN(max_neurons - length(column_data), 1)];
        end
        excel_data.(fields{k}) = column_data;
    end

    % Graficar las medias de fluorescencia por grabación en un gráfico de barras
    figure;
    bar(recording_means);
    set(gca, 'XTickLabel', recording_labels, 'XTickLabelRotation', 45);
    ylabel('Media de fluorescencia');
    title('Media de fluorescencia por grabación');
    
    % Guardar los datos de fluorescencia media por neurona en un archivo Excel
    filename = 'Fluorescencia_Neurona_Por_Grabacion.xlsx';
    writetable(excel_data, filename, 'Sheet', 1);
    disp(['Datos de fluorescencia por neurona guardados en el archivo Excel: ', filename]);
end
