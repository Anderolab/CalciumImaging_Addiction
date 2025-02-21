 function correlateFluorescenceWithBehavior_synchronized(Experiment_trial)
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
    
    % Definir los tipos de eventos disponibles
    all_event_types = {'R', 'K', 'U', 'W', 'L', 'N', 'J'};
    
    % Seleccionar los tipos de eventos que se desean analizar
    selected_event_types_idx = listdlg('PromptString', 'Selecciona los tipos de eventos a analizar:', ...
                                       'SelectionMode', 'multiple', ...
                                       'ListString', all_event_types);
    if isempty(selected_event_types_idx)
        disp('No se seleccionaron tipos de eventos. Proceso cancelado.');
        return;
    end
    
    % Obtener los eventos seleccionados
    selected_event_types = all_event_types(selected_event_types_idx);
    
    % Proceso para cada sesión seleccionada
    for i = selected_sessions_idx
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

        % Variables para concatenar todas las grabaciones
        total_fluorescence = [];
        total_binarized_events = struct(); % Inicializar dinámicamente los tipos de eventos seleccionados
        
        % Procesar las grabaciones seleccionadas
        for j = selected_subfolders_idx
            subfolder = experiment.(subfolder_names{j});
            
            % Obtener el timestamp de la grabación de calcio (en milisegundos)
            calcium_time = subfolder.time;

            % Aplicar filtro de neuronas buenas si se seleccionó un archivo
            if ~isempty(good_neurons_files{j})
                good_neurons = good_neurons_files{j}.good_neurons; % Usar la variable good_neurons del archivo cargado
                FiltTraces_good = subfolder.FiltTraces(:, good_neurons); % Filtrar trazas de neuronas buenas
                global_fluorescence = mean(FiltTraces_good, 2); % Fluorescencia global solo con neuronas buenas
                disp(['Usando solo las neuronas buenas para ', subfolder_names{j}]);
            else
                global_fluorescence = mean(subfolder.FiltTraces, 2); % Usar todas las neuronas
                disp(['Usando todas las neuronas para ', subfolder_names{j}]);
            end

            % Depuración: Mostrar longitud de la fluorescencia para la grabación actual
            disp(['Longitud de global_fluorescence para ', subfolder_names{j}, ': ', num2str(length(global_fluorescence))]);

            % Concatenar global_fluorescence solo una vez por grabación
            total_fluorescence = [total_fluorescence; global_fluorescence];

            % Binarizar los eventos para correlacionar
            binarized_events = struct();
            for k = 1:length(selected_event_types)
                event_type = selected_event_types{k};
                event_times = experiment.(event_type);
                if isempty(event_times)
                    continue;
                end
                
                % Convertir eventos de centisegundos a milisegundos
                event_times_ms = event_times * 10; % Centisegundos a milisegundos

                % Binarizar los eventos dentro del rango de tiempo de la grabación actual
                binarized_events.(event_type) = binarizeEvents(calcium_time, event_times_ms);

                % Depuración: Mostrar longitud de eventos binarizados
                disp(['Longitud de binarized_events (evento ', event_type, ') para ', subfolder_names{j}, ': ', num2str(length(binarized_events.(event_type)))]);

                % % Calcular correlación de Pearson para la grabación actual
                % if length(global_fluorescence) == length(binarized_events.(event_type))
                %     pearson_corr = corr(global_fluorescence, binarized_events.(event_type), 'Rows', 'complete');
                %     fprintf('Correlación de Pearson (evento %s) para %s: %.4f\n', event_type, subfolder_names{j}, pearson_corr);
                % else
                %     disp(['Error: Longitudes desiguales para correlación en grabación ', subfolder_names{j}, ' para el evento ', event_type]);
                % end

                % Concatenar los eventos binarizados
                if ~isfield(total_binarized_events, event_type)
                    total_binarized_events.(event_type) = [];
                end
                total_binarized_events.(event_type) = [total_binarized_events.(event_type); binarized_events.(event_type)];
            end

            % Si es la primera grabación, no necesitamos ningún desfase.
            if j == selected_subfolders_idx(1)
                % Correlacionar los eventos con la primera grabación de calcio
                correlateRecordingWithEvents(experiment, subfolder, calcium_time, 'first', subfolder_names{j}, global_fluorescence, selected_event_types);
            else
                % Obtener la hora de la grabación actual y la anterior
                current_time = extractTimeFromSubfolder(subfolder_names{j});
                previous_time = extractTimeFromSubfolder(subfolder_names{1});
                
                % Calcular el desfase temporal entre grabaciones en milisegundos
                time_difference = (current_time - previous_time) * 1000; % Convertir segundos a milisegundos
                
                % Correlacionar los eventos con la grabación actual, ajustando el desfase
                correlateRecordingWithEvents(experiment, subfolder, calcium_time, time_difference, subfolder_names{j}, global_fluorescence, selected_event_types);
            end
        end

        % % Correlación global (todas las grabaciones concatenadas)
        % fprintf('Correlación de Pearson global (todas las grabaciones concatenadas):\n');
        % for k = 1:length(selected_event_types)
        %     event_type = selected_event_types{k};
        %     if ~isempty(total_binarized_events.(event_type))
        %         % Depuración: Mostrar longitudes de fluorescencia total y eventos concatenados
        %         disp(['Longitud de total_fluorescence: ', num2str(length(total_fluorescence))]);
        %         disp(['Longitud de total_binarized_events (evento ', event_type, '): ', num2str(length(total_binarized_events.(event_type)))]);
        % 
        %         % Verificar si las longitudes coinciden antes de correlacionar
        %         if length(total_fluorescence) == length(total_binarized_events.(event_type))
        %             pearson_corr_total = corr(total_fluorescence, total_binarized_events.(event_type), 'Rows', 'complete');
        %             fprintf('Correlación de Pearson global (evento %s): %.4f\n', event_type, pearson_corr_total);
        %         else
        %             disp(['Error: Longitudes desiguales para correlación global en evento ', event_type]);
        %         end
        %     end
        % end
    end
end

% Función para binarizar eventos según el tiempo de la grabación
function binarized_vector = binarizeEvents(time_vector, event_times_ms)
    binarized_vector = zeros(length(time_vector), 1);
    for i = 1:length(event_times_ms)
        event_time = event_times_ms(i);
        % Encuentra el índice más cercano en el tiempo de la grabación
        closest_index = findClosestIndex(time_vector, event_time);
        binarized_vector(closest_index) = 1;
    end
end

% Función para correlacionar una grabación de calcio con eventos
function correlateRecordingWithEvents(experiment, subfolder, calcium_time, time_offset, recording_name, global_fluorescence, event_types)
    % Graficar la fluorescencia global
    figure;
    plot(calcium_time / 1000, global_fluorescence, 'k'); % Fluorescencia global en negro
    hold on;

    % Definir colores para cada tipo de evento
    colors = lines(length(event_types)); % Usar diferentes colores para los eventos

    % Procesar los tipos de eventos seleccionados
    for k = 1:length(event_types)
        event_type = event_types{k};
        event_times = experiment.(event_type);
        if isempty(event_times)
            continue;
        end

        % Convertir eventos de centisegundos a milisegundos
        event_times_ms = event_times * 10; % Centisegundos a milisegundos

        if ~ischar(time_offset) % No es la primera grabación, ajustar por el desfase
            event_times_ms = event_times_ms - time_offset;
        end

        % Filtrar eventos que están dentro del rango de la grabación actual
        valid_event_times = event_times_ms(event_times_ms >= 0 & event_times_ms <= max(calcium_time));

        % Buscar los frames correspondientes a los tiempos de los eventos
        event_indices = arrayfun(@(x) findClosestIndex(calcium_time, x), valid_event_times);

        % Obtener fluorescencia en los eventos
        event_fluorescence = global_fluorescence(event_indices);

        % Graficar los eventos en diferentes colores
        scatter(calcium_time(event_indices) / 1000, event_fluorescence, 50, colors(k, :), 'filled'); 
    end

    % Añadir leyenda con los tipos de eventos
    legend_labels = ['Fluorescencia global', event_types];
    %legend_labels = ['Fluorescencia global', 'Palancazos'];
    legend(legend_labels, 'Location', 'best');

    xlabel('Tiempo (segundos)');
    ylabel('Fluorescencia global');
    title(['Fluorescencia y eventos para grabación: ', strrep(recording_name, '_', ' ')]);
    hold off;
end


% Función para encontrar el índice más cercano en el timestamp
function index = findClosestIndex(time_vector, event_time)
    [~, index] = min(abs(time_vector - event_time));
end

% Función para extraer la hora desde el nombre de la carpeta
function time_seconds = extractTimeFromSubfolder(subfolder_name)
    time_pattern = regexp(subfolder_name, 'H(\d+)_M(\d+)_S(\d+)', 'tokens');
    
    if isempty(time_pattern)
        error('No se pudo extraer el tiempo del nombre de la carpeta');
    end
    
    time_parts = str2double(time_pattern{1});
    time_seconds = time_parts(1) * 3600 + time_parts(2) * 60 + time_parts(3); % Convertir a segundos
end
